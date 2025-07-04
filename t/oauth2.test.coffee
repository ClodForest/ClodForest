# FILENAME: { ClodForest/t/oauth2.test.coffee }
# OAuth2 Implementation Tests
# Tests OAuth2 functionality against RFC 6749 specification

kava = require 'kava'
http = require 'http'
crypto = require 'crypto'

# Import OAuth2 modules
oauth2 = require '../src/coordinator/lib/oauth2'
oauth2Handler = require '../src/coordinator/handlers/oauth'
oauth2Middleware = require '../src/coordinator/lib/oauth2/middleware'

kava.suite 'OAuth2 Implementation Tests', (suite, test) ->

  # Test OAuth2 Core Library
  suite 'OAuth2 Core Library', (suite, test) ->

    test 'should export all required OAuth2 functions', (done) ->
      requiredFunctions = [
        'registerClient', 'validateClient', 'createAuthCode',
        'exchangeAuthCode', 'refreshAccessToken', 'validateAccessToken'
      ]
      
      for func in requiredFunctions
        if typeof oauth2[func] isnt 'function'
          return done(new Error("Missing OAuth2 function: #{func}"))
      
      done()

    test 'should register client with valid parameters', (done) ->
      clientData =
        name: 'Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read write'
      
      client = oauth2.registerClient(clientData)
      
      # Validate client structure per RFC 6749 Section 2.2
      if not client.clientId or typeof client.clientId isnt 'string'
        return done(new Error('Client must have valid clientId'))
      
      if not client.clientSecret or typeof client.clientSecret isnt 'string'
        return done(new Error('Client must have valid clientSecret'))
      
      if client.name isnt clientData.name
        return done(new Error('Client name mismatch'))
      
      if not Array.isArray(client.redirectUris)
        return done(new Error('Client must have redirectUris array'))
      
      done()

    test 'should validate client credentials correctly', (done) ->
      # Register a test client
      clientData =
        name: 'Validation Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      
      client = oauth2.registerClient(clientData)
      
      # Test valid credentials
      validatedClient = oauth2.validateClient(client.clientId, client.clientSecret)
      if not validatedClient
        return done(new Error('Valid client credentials should be accepted'))
      
      # Test invalid client ID
      invalidClient = oauth2.validateClient('invalid-id', client.clientSecret)
      if invalidClient
        return done(new Error('Invalid client ID should be rejected'))
      
      # Test invalid client secret
      invalidSecret = oauth2.validateClient(client.clientId, 'invalid-secret')
      if invalidSecret
        return done(new Error('Invalid client secret should be rejected'))
      
      done()

    test 'should create and validate authorization codes per RFC 6749 Section 4.1', (done) ->
      # Register a test client
      client = oauth2.registerClient({
        name: 'Auth Code Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create authorization code
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      if not code or typeof code isnt 'string'
        return done(new Error('Authorization code must be a non-empty string'))
      
      # Exchange code for tokens
      result = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if result.error
        return done(new Error("Code exchange failed: #{result.error}"))
      
      # Validate token structure per RFC 6749 Section 5.1
      if not result.accessToken or typeof result.accessToken isnt 'string'
        return done(new Error('Must return valid access token'))
      
      if not result.refreshToken or typeof result.refreshToken isnt 'string'
        return done(new Error('Must return valid refresh token'))
      
      if result.tokenType isnt 'Bearer'
        return done(new Error('Token type must be Bearer'))
      
      if not result.expiresIn or typeof result.expiresIn isnt 'number'
        return done(new Error('Must return expires_in as number'))
      
      done()

    test 'should enforce authorization code single-use per RFC 6749 Section 4.1.2', (done) ->
      # Register a test client
      client = oauth2.registerClient({
        name: 'Single Use Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create authorization code
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      # First exchange should succeed
      result1 = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      if result1.error
        return done(new Error("First code exchange should succeed"))
      
      # Second exchange should fail
      result2 = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      if not result2.error or result2.error isnt 'invalid_grant'
        return done(new Error("Second code exchange should fail with invalid_grant"))
      
      done()

    test 'should validate redirect URI matching per RFC 6749 Section 4.1.3', (done) ->
      # Register a test client
      client = oauth2.registerClient({
        name: 'Redirect URI Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create authorization code with specific redirect URI
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      # Exchange with matching redirect URI should succeed
      result1 = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      if result1.error
        return done(new Error("Exchange with matching redirect URI should succeed"))
      
      # Create another code for mismatched URI test
      code2 = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      # Exchange with different redirect URI should fail
      result2 = oauth2.exchangeAuthCode(code2, client.clientId, 'http://different.com/callback')
      if not result2.error or result2.error isnt 'invalid_grant'
        return done(new Error("Exchange with mismatched redirect URI should fail"))
      
      done()

    test 'should handle refresh token flow per RFC 6749 Section 6', (done) ->
      # Register a test client
      client = oauth2.registerClient({
        name: 'Refresh Token Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read write'
      })
      
      # Create initial tokens
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read write')
      initialTokens = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if initialTokens.error
        return done(new Error("Initial token creation failed"))
      
      # Refresh the access token
      refreshResult = oauth2.refreshAccessToken(initialTokens.refreshToken, client.clientId)
      
      if refreshResult.error
        return done(new Error("Token refresh failed: #{refreshResult.error}"))
      
      # Validate new tokens
      if not refreshResult.accessToken or refreshResult.accessToken is initialTokens.accessToken
        return done(new Error("Refresh should return new access token"))
      
      if not refreshResult.refreshToken
        return done(new Error("Refresh should return new refresh token"))
      
      # Old refresh token should be invalidated
      oldRefreshResult = oauth2.refreshAccessToken(initialTokens.refreshToken, client.clientId)
      if not oldRefreshResult.error or oldRefreshResult.error isnt 'invalid_grant'
        return done(new Error("Old refresh token should be invalidated"))
      
      done()

    test 'should validate access tokens correctly', (done) ->
      # Register a test client
      client = oauth2.registerClient({
        name: 'Token Validation Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create tokens
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      tokens = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if tokens.error
        return done(new Error("Token creation failed"))
      
      # Validate valid token
      tokenData = oauth2.validateAccessToken(tokens.accessToken)
      if not tokenData
        return done(new Error("Valid access token should be accepted"))
      
      if tokenData.clientId isnt client.clientId
        return done(new Error("Token should contain correct client ID"))
      
      if tokenData.userId isnt 'user123'
        return done(new Error("Token should contain correct user ID"))
      
      # Validate invalid token
      invalidTokenData = oauth2.validateAccessToken('invalid-token')
      if invalidTokenData
        return done(new Error("Invalid access token should be rejected"))
      
      done()

  # Test OAuth2 HTTP Handlers
  suite 'OAuth2 HTTP Handlers', (suite, test) ->

    test 'should export all required handler functions', (done) ->
      requiredHandlers = ['authorize', 'authorizeSubmit', 'token', 'registerClient']
      
      for handler in requiredHandlers
        if typeof oauth2Handler[handler] isnt 'function'
          return done(new Error("Missing OAuth2 handler: #{handler}"))
      
      done()

    test 'should handle authorization endpoint GET requests per RFC 6749 Section 4.1.1', (done) ->
      # Mock request and response
      req =
        query:
          client_id: 'test-client'
          redirect_uri: 'http://localhost:3000/callback'
          response_type: 'code'
          scope: 'read'
          state: 'xyz123'
      
      res =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
        send: (html) -> @htmlData = html; @
      
      oauth2Handler.authorize(req, res)
      
      # Should return HTML login form for valid requests
      if not res.htmlData or typeof res.htmlData isnt 'string'
        return done(new Error("Authorization endpoint should return HTML login form"))
      
      if not res.htmlData.includes('form')
        return done(new Error("Response should contain login form"))
      
      if not res.htmlData.includes(req.query.client_id)
        return done(new Error("Form should include client_id"))
      
      done()

    test 'should validate required parameters per RFC 6749 Section 4.1.1', (done) ->
      # Test missing client_id
      req1 =
        query:
          redirect_uri: 'http://localhost:3000/callback'
          response_type: 'code'
      
      res1 =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
        send: (html) -> @htmlData = html; @
      
      oauth2Handler.authorize(req1, res1)
      
      if res1.statusCode isnt 400
        return done(new Error("Missing client_id should return 400"))
      
      if not res1.jsonData?.error or res1.jsonData.error isnt 'invalid_request'
        return done(new Error("Should return invalid_request error"))
      
      # Test invalid response_type
      req2 =
        query:
          client_id: 'test-client'
          redirect_uri: 'http://localhost:3000/callback'
          response_type: 'invalid'
      
      res2 =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
        send: (html) -> @htmlData = html; @
      
      oauth2Handler.authorize(req2, res2)
      
      if res2.statusCode isnt 400
        return done(new Error("Invalid response_type should return 400"))
      
      done()

    test 'should handle token endpoint requests per RFC 6749 Section 4.1.3', (done) ->
      # First register a client
      client = oauth2.registerClient({
        name: 'Token Endpoint Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create authorization code
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      # Mock token request
      credentials = Buffer.from("#{client.clientId}:#{client.clientSecret}").toString('base64')
      
      req =
        body:
          grant_type: 'authorization_code'
          code: code
          redirect_uri: 'http://localhost:3000/callback'
        get: (header) ->
          if header is 'Authorization'
            return "Basic #{credentials}"
          null
      
      res =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
      
      oauth2Handler.token(req, res)
      
      # Should return successful token response
      if res.statusCode and res.statusCode isnt 200
        return done(new Error("Valid token request should return 200"))
      
      if not res.jsonData?.access_token
        return done(new Error("Response should include access_token"))
      
      if res.jsonData.token_type isnt 'Bearer'
        return done(new Error("Token type should be Bearer"))
      
      if not res.jsonData.expires_in
        return done(new Error("Response should include expires_in"))
      
      done()

    test 'should handle client credentials grant per RFC 6749 Section 4.4', (done) ->
      # Register a client
      client = oauth2.registerClient({
        name: 'Client Credentials Test Client'
        redirectUris: []
        scope: 'mcp'
      })
      
      # Mock client credentials request
      credentials = Buffer.from("#{client.clientId}:#{client.clientSecret}").toString('base64')
      
      req =
        body:
          grant_type: 'client_credentials'
          scope: 'mcp'
        get: (header) ->
          if header is 'Authorization'
            return "Basic #{credentials}"
          null
      
      res =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
      
      oauth2Handler.token(req, res)
      
      # Should return successful token response
      if res.statusCode and res.statusCode isnt 200
        return done(new Error("Valid client credentials request should return 200"))
      
      if not res.jsonData?.access_token
        return done(new Error("Response should include access_token"))
      
      if res.jsonData.scope isnt 'mcp'
        return done(new Error("Response should include requested scope"))
      
      # Should not include refresh token for client credentials grant
      if res.jsonData.refresh_token
        return done(new Error("Client credentials grant should not return refresh token"))
      
      done()

    test 'should handle client authentication errors per RFC 6749 Section 3.2.1', (done) ->
      # Test missing client credentials
      req1 =
        body:
          grant_type: 'client_credentials'
        get: (header) -> null
      
      res1 =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
      
      oauth2Handler.token(req1, res1)
      
      if res1.statusCode isnt 401
        return done(new Error("Missing client credentials should return 401"))
      
      if res1.jsonData?.error isnt 'invalid_client'
        return done(new Error("Should return invalid_client error"))
      
      # Test invalid client credentials
      req2 =
        body:
          grant_type: 'client_credentials'
        get: (header) ->
          if header is 'Authorization'
            return "Basic #{Buffer.from('invalid:credentials').toString('base64')}"
          null
      
      res2 =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
      
      oauth2Handler.token(req2, res2)
      
      if res2.statusCode isnt 401
        return done(new Error("Invalid client credentials should return 401"))
      
      done()

  # Test OAuth2 Middleware
  suite 'OAuth2 Middleware', (suite, test) ->

    test 'should export required middleware functions', (done) ->
      requiredFunctions = ['requireAuth', 'optionalAuth', 'extractToken']
      
      for func in requiredFunctions
        if typeof oauth2Middleware[func] isnt 'function'
          return done(new Error("Missing middleware function: #{func}"))
      
      done()

    test 'should extract tokens from Authorization header per RFC 6750', (done) ->
      # Test Bearer token extraction
      req1 =
        get: (header) ->
          if header is 'Authorization'
            return 'Bearer abc123token'
          null
        query: {}
      
      token1 = oauth2Middleware.extractToken(req1)
      if token1 isnt 'abc123token'
        return done(new Error("Should extract Bearer token from Authorization header"))
      
      # Test missing Authorization header
      req2 =
        get: (header) -> null
        query: {}
      
      token2 = oauth2Middleware.extractToken(req2)
      if token2 isnt null
        return done(new Error("Should return null when no token present"))
      
      done()

    test 'should require valid authentication', (done) ->
      # Create a valid token first
      client = oauth2.registerClient({
        name: 'Middleware Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      tokens = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if tokens.error
        return done(new Error("Token creation failed"))
      
      # Test valid token
      req1 =
        get: (header) ->
          if header is 'Authorization'
            return "Bearer #{tokens.accessToken}"
          null
        query: {}
      
      res1 =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
      
      middleware1 = oauth2Middleware.requireAuth()
      middleware1 req1, res1, ->
        # Should call next() for valid token
        if not req1.oauth
          return done(new Error("Should attach oauth data to request"))
        
        if req1.oauth.clientId isnt client.clientId
          return done(new Error("Should include correct client ID"))
        
        # Test invalid token
        req2 =
          get: (header) ->
            if header is 'Authorization'
              return 'Bearer invalid-token'
            null
          query: {}
        
        res2 =
          status: (code) -> @statusCode = code; @
          json: (data) -> @jsonData = data; @
        
        middleware2 = oauth2Middleware.requireAuth()
        middleware2 req2, res2, ->
          done(new Error("Should not call next() for invalid token"))
        
        # Should return 401 for invalid token
        if res2.statusCode isnt 401
          return done(new Error("Invalid token should return 401"))
        
        if res2.jsonData?.error isnt 'invalid_token'
          return done(new Error("Should return invalid_token error"))
        
        done()
      
    test 'should enforce scope requirements per RFC 6749 Section 3.3', (done) ->
      # Create a token with specific scope
      client = oauth2.registerClient({
        name: 'Scope Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read write'
      })
      
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      tokens = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if tokens.error
        return done(new Error("Token creation failed"))
      
      # Test token with sufficient scope
      req1 =
        get: (header) ->
          if header is 'Authorization'
            return "Bearer #{tokens.accessToken}"
          null
        query: {}
      
      res1 =
        status: (code) -> @statusCode = code; @
        json: (data) -> @jsonData = data; @
      
      middleware1 = oauth2Middleware.requireAuth('read')
      middleware1 req1, res1, ->
        # Should succeed with sufficient scope
        
        # Test token with insufficient scope
        req2 =
          get: (header) ->
            if header is 'Authorization'
              return "Bearer #{tokens.accessToken}"
            null
          query: {}
        
        res2 =
          status: (code) -> @statusCode = code; @
          json: (data) -> @jsonData = data; @
        
        middleware2 = oauth2Middleware.requireAuth('admin')
        middleware2 req2, res2, ->
          done(new Error("Should not call next() for insufficient scope"))
        
        # Should return 403 for insufficient scope
        if res2.statusCode isnt 403
          return done(new Error("Insufficient scope should return 403"))
        
        if res2.jsonData?.error isnt 'insufficient_scope'
          return done(new Error("Should return insufficient_scope error"))
        
        done()

  # Test OAuth2 Security Requirements
  suite 'OAuth2 Security Requirements', (suite, test) ->

    test 'should generate cryptographically secure tokens per RFC 6749 Section 10.10', (done) ->
      # Register multiple clients and check token uniqueness
      tokens = new Set()
      
      for i in [1..100]
        client = oauth2.registerClient({
          name: "Security Test Client #{i}"
          redirectUris: ['http://localhost:3000/callback']
          scope: 'read'
        })
        
        # Check client ID and secret are unique and sufficiently long
        if client.clientId.length < 16
          return done(new Error("Client ID should be at least 16 characters"))
        
        if client.clientSecret.length < 32
          return done(new Error("Client secret should be at least 32 characters"))
        
        if tokens.has(client.clientId)
          return done(new Error("Client IDs must be unique"))
        
        tokens.add(client.clientId)
      
      done()

    test 'should enforce authorization code expiration per RFC 6749 Section 4.1.2', (done) ->
      client = oauth2.registerClient({
        name: 'Expiration Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create authorization code
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      # Manually expire the code by manipulating internal state
      authCodes = oauth2._stores.authCodes
      authCodeData = authCodes.get(code)
      if authCodeData
        authCodeData.expiresAt = Date.now() - 1000  # Expired 1 second ago
      
      # Try to exchange expired code
      result = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if not result.error or result.error isnt 'invalid_grant'
        return done(new Error("Expired authorization code should be rejected"))
      
      done()

    test 'should enforce access token expiration', (done) ->
      client = oauth2.registerClient({
        name: 'Token Expiration Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      tokens = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      
      if tokens.error
        return done(new Error("Token creation failed"))
      
      # Manually expire the token
      tokenStore = oauth2._stores.tokens
      tokenData = tokenStore.get(tokens.accessToken)
      if tokenData
        tokenData.expiresAt = Date.now() - 1000  # Expired 1 second ago
      
      # Try to validate expired token
      validatedToken = oauth2.validateAccessToken(tokens.accessToken)
      
      if validatedToken
        return done(new Error("Expired access token should be rejected"))
      
      done()

    test 'should prevent authorization code replay attacks per RFC 6749 Section 10.5', (done) ->
      client = oauth2.registerClient({
        name: 'Replay Attack Test Client'
        redirectUris: ['http://localhost:3000/callback']
        scope: 'read'
      })
      
      # Create authorization code
      code = oauth2.createAuthCode(client.clientId, 'user123', 'http://localhost:3000/callback', 'read')
      
      # First exchange should succeed
      result1 = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      if result1.error
        return done(new Error("First code exchange should succeed"))
      
      # Second exchange should fail (code should be consumed)
      result2 = oauth2.exchangeAuthCode(code, client.clientId, 'http://localhost:3000/callback')
      if not result2.error or result2.error isnt 'invalid_grant'
        return done(new Error("Code replay should be prevented"))
      
      done()
