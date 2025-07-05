# FILENAME: { ClodForest/src/oauth/model.coffee }
# OAuth2 data model with file system persistence

fs     = require 'node:fs/promises'
path   = require 'node:path'
crypto = require 'node:crypto'

class OAuth2Model
  constructor: ->
    @dataDir     = path.join process.cwd(), 'data', 'oauth2'
    @clientsFile = path.join @dataDir, 'clients.json'
    @tokensFile  = path.join @dataDir, 'tokens.json'
    @codesFile   = path.join @dataDir, 'codes.json'
    @initialized = false

  init: ->
    return if @initialized
    
    try
      await fs.mkdir @dataDir, recursive: true
      
      # Initialize clients file if it doesn't exist
      try
        await fs.access @clientsFile
      catch
        await fs.writeFile @clientsFile, JSON.stringify([], null, 2)

      # Initialize tokens file if it doesn't exist
      try
        await fs.access @tokensFile
      catch
        await fs.writeFile @tokensFile, JSON.stringify([], null, 2)

      # Initialize codes file if it doesn't exist
      try
        await fs.access @codesFile
      catch
        await fs.writeFile @codesFile, JSON.stringify([], null, 2)
      
      @initialized = true
      console.log 'OAuth2 data directory initialized successfully'
    catch error
      console.error 'Failed to initialize OAuth2 data directory:', error
      throw error

  loadClients: ->
    await @init()
    try
      data = await fs.readFile @clientsFile, 'utf8'
      JSON.parse data
    catch
      []

  saveClients: (clients) ->
    await @init()
    await fs.writeFile @clientsFile, JSON.stringify(clients, null, 2)

  loadTokens: ->
    await @init()
    try
      data = await fs.readFile @tokensFile, 'utf8'
      JSON.parse data
    catch
      []

  saveTokens: (tokens) ->
    await @init()
    await fs.writeFile @tokensFile, JSON.stringify(tokens, null, 2)

  # OAuth2 Server required methods

  getClient: (clientId, clientSecret) ->
    clients = await @loadClients()
    client  = clients.find (c) -> c.id is clientId
    
    return false unless client
    
    # If clientSecret is provided, verify it
    if clientSecret and client.secret isnt clientSecret
      return false

    id:           client.id
    grants:       client.grants or ['client_credentials']
    redirectUris: client.redirectUris or []
    scope:        client.scope or 'mcp read write'

  saveToken: (token, client, user) ->
    tokens = await @loadTokens()
    
    tokenData =
      accessToken:           token.accessToken
      accessTokenExpiresAt:  token.accessTokenExpiresAt
      refreshToken:          token.refreshToken
      refreshTokenExpiresAt: token.refreshTokenExpiresAt
      scope:                 token.scope
      client:                id: client.id
      user:                  user or null
      createdAt:             new Date().toISOString()

    tokens.push tokenData
    await @saveTokens tokens

    tokenData

  getAccessToken: (accessToken) ->
    tokens = await @loadTokens()
    token  = tokens.find (t) -> t.accessToken is accessToken
    
    return false unless token
    
    # Convert string dates back to Date objects (JSON serialization converts dates to strings)
    accessTokenExpiresAt = if token.accessTokenExpiresAt then new Date(token.accessTokenExpiresAt) else null
    
    # Check if token is expired
    if accessTokenExpiresAt and new Date() > accessTokenExpiresAt
      return false

    accessToken:          token.accessToken
    accessTokenExpiresAt: accessTokenExpiresAt  # Return as Date object
    scope:                token.scope
    client:               token.client
    user:                 token.user

  verifyScope: (token, scope) ->
    return false unless token.scope
    
    tokenScopes    = token.scope.split ' '
    requiredScopes = scope.split ' '
    
    requiredScopes.every (s) -> tokenScopes.includes s

  getUserFromClient: (client) ->
    # For client_credentials grant, return a simple user object
    # since this is machine-to-machine authentication
    id:       'system'
    username: client.id

  # Client registration method
  registerClient: (clientData) ->
    clients = await @loadClients()
    
    client =
      id:           crypto.randomUUID()
      secret:       crypto.randomBytes(32).toString('hex')
      name:         clientData.client_name or 'Unnamed Client'
      grants:       clientData.grant_types or ['client_credentials']
      redirectUris: clientData.redirect_uris or []
      scope:        clientData.scope or 'mcp read write'
      createdAt:    new Date().toISOString()

    clients.push client
    await @saveClients clients

    client

  # Authorization code flow methods
  loadCodes: ->
    await @init()
    try
      data = await fs.readFile @codesFile, 'utf8'
      JSON.parse data
    catch
      []

  saveCodes: (codes) ->
    await @init()
    await fs.writeFile @codesFile, JSON.stringify(codes, null, 2)

  saveAuthorizationCode: (code, client, user) ->
    codes = await @loadCodes()
    
    codeData =
      authorizationCode: code.authorizationCode
      expiresAt:         code.expiresAt
      redirectUri:       code.redirectUri
      scope:             code.scope
      client:            id: client.id
      user:              user or null
      createdAt:         new Date().toISOString()

    codes.push codeData
    await @saveCodes codes

    codeData

  getAuthorizationCode: (authorizationCode) ->
    codes = await @loadCodes()
    code  = codes.find (c) -> c.authorizationCode is authorizationCode
    
    return false unless code
    
    # Convert string dates back to Date objects
    expiresAt = if code.expiresAt then new Date(code.expiresAt) else null
    
    # Check if code is expired
    if expiresAt and new Date() > expiresAt
      return false

    authorizationCode: code.authorizationCode
    expiresAt:         expiresAt
    redirectUri:       code.redirectUri
    scope:             code.scope
    client:            code.client
    user:              code.user

  revokeAuthorizationCode: (authorizationCode) ->
    codes = await @loadCodes()
    
    # Remove the used authorization code
    remainingCodes = codes.filter (c) -> c.authorizationCode isnt authorizationCode.authorizationCode
    await @saveCodes remainingCodes
    
    true

  getUser: (username, password) ->
    # For MCP Inspector, we'll allow a simple user authentication
    # In a real implementation, this would check against a user database
    if username is 'mcp-user'
      id:       'mcp-user'
      username: 'mcp-user'
    else
      false

  # Clean up expired tokens and codes
  cleanupExpiredTokens: ->
    tokens = await @loadTokens()
    codes  = await @loadCodes()
    now    = new Date()
    
    validTokens = tokens.filter (token) ->
      return true unless token.accessTokenExpiresAt
      new Date(token.accessTokenExpiresAt) > now

    validCodes = codes.filter (code) ->
      return true unless code.expiresAt
      new Date(code.expiresAt) > now

    if validTokens.length isnt tokens.length
      await @saveTokens validTokens
      console.log "Cleaned up #{tokens.length - validTokens.length} expired tokens"

    if validCodes.length isnt codes.length
      await @saveCodes validCodes
      console.log "Cleaned up #{codes.length - validCodes.length} expired authorization codes"

module.exports = OAuth2Model
