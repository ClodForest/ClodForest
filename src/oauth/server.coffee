# FILENAME: { ClodForest/src/oauth/server.coffee }
# OAuth2 server setup and routes

express      = require 'express'
OAuth2Server = require 'oauth2-server'
OAuth2Model  = require './model'
{ logger }   = require '../lib/logger'
crypto       = require 'node:crypto'

router = express.Router()
model  = new OAuth2Model()

# Initialize OAuth2 server
oauth = new OAuth2Server
  model:                        model
  grants:                       ['client_credentials', 'authorization_code', 'refresh_token']
  debug:                        process.env.NODE_ENV is 'development'
  accessTokenLifetime:          3600 # 1 hour
  refreshTokenLifetime:         86400 # 24 hours
  allowBearerTokensInQueryString: false
  allowEmptyState:              false
  authorizationCodeLifetime:    300 # 5 minutes

# Client registration endpoint
router.post '/register', (req, res) ->
  try
    # Debug logging for MCP Inspector troubleshooting
    logger.oauth 'Client registration request received', {
      headers: req.headers
      body: req.body
      contentType: req.get('Content-Type')
      method: req.method
      url: req.url
    }

    { client_name, grant_types, redirect_uris, scope } = req.body

    # Validate required fields
    unless client_name
      logger.oauth 'Client registration failed: missing client_name', {
        body: req.body
        hasClientName: !!client_name
      }
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'client_name is required'

    # Validate grant types
    allowedGrants   = ['client_credentials', 'authorization_code', 'refresh_token']
    requestedGrants = grant_types or ['client_credentials']
    
    logger.oauth 'Grant type validation', {
      allowedGrants: allowedGrants
      requestedGrants: requestedGrants
      isValid: requestedGrants.every (grant) -> allowedGrants.includes grant
    }
    
    unless requestedGrants.every (grant) -> allowedGrants.includes grant
      logger.oauth 'Client registration failed: invalid grant types', {
        allowedGrants: allowedGrants
        requestedGrants: requestedGrants
      }
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'Supported grant types: client_credentials, authorization_code, refresh_token'

    client = await model.registerClient
      client_name:   client_name
      grant_types:   requestedGrants
      redirect_uris: redirect_uris
      scope:         scope

    # Return client registration response (RFC 7591)
    res.status(201).json
      client_id:                client.id
      client_secret:            client.secret
      client_name:              client.name
      grant_types:              client.grants
      scope:                    client.scope
      client_id_issued_at:      Math.floor(new Date(client.createdAt).getTime() / 1000)
      client_secret_expires_at: 0 # Never expires

  catch error
    logger.oauth 'Client registration error', { 
      error: error.message
      stack: error.stack
      client_name: req.body?.client_name
      requestBody: req.body
    }
    res.status(500).json
      error:             'server_error'
      error_description: 'Internal server error'

# Authorization endpoint for authorization code flow
router.get '/authorize', (req, res) ->
  try
    logger.oauth 'Authorization request received', {
      query: req.query
      headers: req.headers
    }
    
    # Validate required parameters
    { response_type, client_id, redirect_uri, scope, state } = req.query
    
    unless response_type is 'code'
      logger.oauth 'Invalid response_type', { response_type }
      return res.status(400).json
        error:             'unsupported_response_type'
        error_description: 'Only response_type=code is supported'
    
    unless client_id
      logger.oauth 'Missing client_id'
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'client_id is required'
    
    unless redirect_uri
      logger.oauth 'Missing redirect_uri'
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'redirect_uri is required'
    
    # Get client to validate redirect_uri
    client = await model.getClient(client_id)
    unless client
      logger.oauth 'Invalid client_id', { client_id }
      return res.status(400).json
        error:             'invalid_client'
        error_description: 'Invalid client_id'
    
    # Validate redirect_uri
    unless client.redirectUris.includes(redirect_uri)
      logger.oauth 'Invalid redirect_uri', { 
        redirect_uri, 
        allowed: client.redirectUris 
      }
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'Invalid redirect_uri'
    
    # For MCP Inspector, we'll auto-approve the authorization
    # In a real implementation, this would show a consent screen
    logger.oauth 'Auto-approving authorization for MCP client', {
      client_id,
      scope,
      redirect_uri
    }
    
    # Generate authorization code
    authCode = crypto.randomBytes(32).toString('hex')
    expiresAt = new Date(Date.now() + 5 * 60 * 1000) # 5 minutes
    
    # Save authorization code
    await model.saveAuthorizationCode(
      {
        authorizationCode: authCode
        expiresAt: expiresAt
        redirectUri: redirect_uri
        scope: scope or client.scope
      },
      client,
      { id: 'mcp-user', username: 'mcp-user' } # Default user for MCP
    )
    
    logger.oauth 'Authorization code generated', {
      code: authCode.substring(0, 10) + '...'
      clientId: client_id
      redirectUri: redirect_uri
      expiresAt: expiresAt
    }
    
    # Redirect back to client with authorization code
    redirectUrl = new URL(redirect_uri)
    redirectUrl.searchParams.set('code', authCode)
    if state
      redirectUrl.searchParams.set('state', state)
    
    res.redirect(redirectUrl.toString())

  catch error
    logger.oauth 'Authorization endpoint error', {
      name: error.name
      message: error.message
      code: error.code
      stack: error.stack
    }
    
    # Handle redirect_uri for errors if available
    if req.query.redirect_uri
      try
        redirectUrl = new URL(req.query.redirect_uri)
        redirectUrl.searchParams.set('error', 'server_error')
        redirectUrl.searchParams.set('error_description', 'Internal server error')
        if req.query.state
          redirectUrl.searchParams.set('state', req.query.state)
        return res.redirect(redirectUrl.toString())
      catch redirectError
        logger.oauth 'Failed to redirect error', { redirectError: redirectError.message }

    res.status(500).json
      error:             'server_error'
      error_description: 'Internal server error'

# Token endpoint
router.post '/token', (req, res) ->
  try
    logger.oauth 'Token request received', {
      grant_type: req.body.grant_type
      client_id: req.body.client_id
      scope: req.body.scope
    }
    
    request  = new OAuth2Server.Request req
    response = new OAuth2Server.Response res

    token = await oauth.token request, response
    
    logger.oauth 'Token generated successfully', {
      accessToken: token.accessToken?.substring(0, 10) + '...'
      expiresAt: token.accessTokenExpiresAt
      scope: token.scope
    }
    
    res.json
      access_token: token.accessToken
      token_type:   'Bearer'
      expires_in:   Math.floor((token.accessTokenExpiresAt - new Date()) / 1000)
      scope:        token.scope

  catch error
    logger.oauth 'Token endpoint error', {
      name: error.name
      message: error.message
      code: error.code
      stack: error.stack
    }
    
    # Handle OAuth2 errors
    if error.name is 'OAuthError'
      return res.status(error.code or 400).json
        error:             error.name.toLowerCase().replace('error', '')
        error_description: error.message

    res.status(500).json
      error:             'server_error'
      error_description: 'Internal server error'

# Token introspection endpoint (RFC 7662)
router.post '/introspect', (req, res) ->
  try
    { token, token_type_hint } = req.body

    unless token
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'token parameter is required'

    tokenData = await model.getAccessToken token
    
    unless tokenData
      return res.json active: false

    # Check if token is expired
    isActive = not tokenData.accessTokenExpiresAt or 
               new Date() < new Date(tokenData.accessTokenExpiresAt)

    unless isActive
      return res.json active: false

    res.json
      active:     true
      scope:      tokenData.scope
      client_id:  tokenData.client.id
      token_type: 'Bearer'
      exp:        if tokenData.accessTokenExpiresAt
                    Math.floor(new Date(tokenData.accessTokenExpiresAt).getTime() / 1000)
                  else
                    undefined

  catch error
    logger.oauth 'Token introspection error', { error: error.message, stack: error.stack }
    res.status(500).json
      error:             'server_error'
      error_description: 'Internal server error'

# Cleanup expired tokens periodically
setInterval (->
  try
    await model.cleanupExpiredTokens()
  catch error
    logger.oauth 'Token cleanup error', { error: error.message }
), 60000 # Every minute

module.exports = router
