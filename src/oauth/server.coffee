# FILENAME: { ClodForest/src/oauth/server.coffee }
# OAuth2 server setup and routes

express      = require 'express'
OAuth2Server = require 'oauth2-server'
OAuth2Model  = require './model'

router = express.Router()
model  = new OAuth2Model()

# Initialize OAuth2 server
oauth = new OAuth2Server
  model:                        model
  grants:                       ['client_credentials']
  debug:                        process.env.NODE_ENV is 'development'
  accessTokenLifetime:          3600 # 1 hour
  allowBearerTokensInQueryString: false
  allowEmptyState:              false
  authorizationCodeLifetime:    300 # 5 minutes

# Client registration endpoint
router.post '/register', (req, res) ->
  try
    { client_name, grant_types, redirect_uris, scope } = req.body

    # Validate required fields
    unless client_name
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'client_name is required'

    # Validate grant types
    allowedGrants   = ['client_credentials']
    requestedGrants = grant_types or ['client_credentials']
    
    unless requestedGrants.every (grant) -> allowedGrants.includes grant
      return res.status(400).json
        error:             'invalid_request'
        error_description: 'Only client_credentials grant type is supported'

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
    console.error 'Client registration error:', error
    res.status(500).json
      error:             'server_error'
      error_description: 'Internal server error'

# Token endpoint
router.post '/token', (req, res) ->
  try
    console.log 'Token request received:', {
      grant_type: req.body.grant_type
      client_id: req.body.client_id
      scope: req.body.scope
    }
    
    request  = new OAuth2Server.Request req
    response = new OAuth2Server.Response res

    token = await oauth.token request, response
    
    console.log 'Token generated successfully:', {
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
    console.error 'Token endpoint error details:', {
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
    console.error 'Token introspection error:', error
    res.status(500).json
      error:             'server_error'
      error_description: 'Internal server error'

# Cleanup expired tokens periodically
setInterval (->
  try
    await model.cleanupExpiredTokens()
  catch error
    console.error 'Token cleanup error:', error
), 60000 # Every minute

module.exports = router
