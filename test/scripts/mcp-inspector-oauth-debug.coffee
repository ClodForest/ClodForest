# FILENAME: { ClodForest/test/scripts/mcp-inspector-oauth-debug.coffee }
# Enhanced OAuth2 server for debugging MCP Inspector flows
# Based on oauth-minimal.coffee with additional logging and MCP Inspector-specific features

express              = require 'express'
{Provider}           = require 'oidc-provider'
{SignJWT, jwtVerify} = require 'jose'
crypto               = require 'crypto'
path                 = require 'path'

CONFIG =
  PORT:          process.env.PORT          or 3000
  ISSUER:        process.env.ISSUER        or "http://localhost:#{process.env.PORT or 3000}"
  SECRET_KEY:    process.env.SECRET_KEY    or crypto.randomBytes 32
  CLIENT_ID:     process.env.CLIENT_ID     or 'mcp-inspector-test'
  CLIENT_SECRET: process.env.CLIENT_SECRET or 'mcp-inspector-secret'
  REDIRECT_URI:  process.env.REDIRECT_URI  or "http://localhost:6274/oauth/callback/debug"

# Debug logger
debug = (label, data) ->
  timestamp = new Date().toISOString()
  console.log "#{timestamp} [#{label}]", JSON.stringify(data, null, 2)

# Enhanced OIDC config with MCP Inspector compatibility
oidcConfig =
  clients: [
    client_id:     CONFIG.CLIENT_ID
    client_secret: CONFIG.CLIENT_SECRET
    redirect_uris: [CONFIG.REDIRECT_URI]
    grant_types:   ['authorization_code']
    response_types: ['code']
    scope:         'openid mcp read write'  # Include all scopes MCP Inspector needs
    token_endpoint_auth_method: 'none'      # MCP Inspector uses public client
  ]

  # Enhanced interaction logging
  interactions:
    url: (ctx, interaction) ->
      debug 'INTERACTION_URL', {
        uid: interaction.uid
        prompt: interaction.prompt
        params: interaction.params
        session: interaction.session
      }
      "/interaction/#{interaction.uid}"

  # Simple in-memory account store
  findAccount: (ctx, id) ->
    debug 'FIND_ACCOUNT', { id }
    accountId: id
    claims: ->
      debug 'ACCOUNT_CLAIMS', { id }
      sub:   id
      name:  "MCP Test User #{id}"
      email: "mcptest#{id}@example.com"

  features:
    devInteractions: enabled: false
    clientCredentials: enabled: true
    resourceIndicators: enabled: true

  # Enhanced error handling
  renderError: (ctx, out, error) ->
    debug 'OIDC_ERROR', {
      error: error.error
      description: error.error_description
      status: error.status
      path: ctx.path
      method: ctx.method
      query: ctx.query
      body: ctx.request.body
    }
    ctx.type = 'application/json'
    ctx.body = {
      error: error.error
      error_description: error.error_description
    }

app      = express()
provider = new Provider CONFIG.ISSUER, oidcConfig

# Enhanced request logging middleware
app.use (req, res, next) ->
  debug 'REQUEST', {
    method: req.method
    path: req.path
    query: req.query
    headers: req.headers
    body: req.body if req.method in ['POST', 'PUT', 'PATCH']
  }
  next()

app.use express.json()
app.use express.urlencoded extended: true

# Enhanced OIDC provider with event logging
provider.on 'grant.success', (ctx) ->
  debug 'GRANT_SUCCESS', {
    grant_type: ctx.oidc.params.grant_type
    client_id: ctx.oidc.client?.clientId
    scope: ctx.oidc.params.scope
    resource: ctx.oidc.params.resource
  }

provider.on 'grant.error', (ctx, error) ->
  debug 'GRANT_ERROR', {
    error: error.message
    grant_type: ctx.oidc.params.grant_type
    client_id: ctx.oidc.client?.clientId
    scope: ctx.oidc.params.scope
    stack: error.stack
  }

provider.on 'authorization.success', (ctx) ->
  debug 'AUTHORIZATION_SUCCESS', {
    client_id: ctx.oidc.client?.clientId
    scope: ctx.oidc.params.scope
    response_type: ctx.oidc.params.response_type
    redirect_uri: ctx.oidc.params.redirect_uri
  }

provider.on 'authorization.error', (ctx, error) ->
  debug 'AUTHORIZATION_ERROR', {
    error: error.message
    client_id: ctx.oidc.params.client_id
    scope: ctx.oidc.params.scope
    stack: error.stack
  }

app.use '/oidc', provider.callback()

# Enhanced token verification with debugging
verifyToken = (req, res, next) ->
  authHeader = req.headers.authorization
  debug 'TOKEN_VERIFICATION', { authHeader: authHeader?.substring(0, 20) + '...' }

  unless authHeader?.startsWith 'Bearer '
    debug 'TOKEN_ERROR', { error: 'Missing or invalid authorization header' }
    return res.status(401).json error: 'Missing or invalid authorization header'

  token = authHeader.substring 7

  try
    secret = new TextEncoder().encode CONFIG.SECRET_KEY
    {payload} = await jwtVerify token, secret
    debug 'TOKEN_SUCCESS', { payload }

    req.user = payload
    next()
  catch error
    debug 'TOKEN_ERROR', { error: error.message }
    res.status(401).json error: 'Invalid token'

# Enhanced root endpoint with MCP Inspector info
app.get '/', (req, res) ->
  debug 'ROOT_REQUEST', {}
  res.json
    message: 'MCP Inspector OAuth2 Debug Server'
    endpoints:
      authorization: "#{CONFIG.ISSUER}/oidc/auth"
      token:         "#{CONFIG.ISSUER}/oidc/token"
      userinfo:      "#{CONFIG.ISSUER}/oidc/me"
      protected_api: "#{CONFIG.ISSUER}/api/mcp"
    client:
      client_id:     CONFIG.CLIENT_ID
      redirect_uri:  CONFIG.REDIRECT_URI
      scope:         'openid mcp read write'
    mcp_inspector:
      expected_redirect_uri: CONFIG.REDIRECT_URI
      supported_scopes: ['openid', 'mcp', 'read', 'write']

# Enhanced interaction handler with detailed logging
app.get '/interaction/:uid', (req, res) ->
  debug 'INTERACTION_REQUEST', { uid: req.params.uid }
  
  try
    interaction = await provider.interactionDetails req, res
    debug 'INTERACTION_DETAILS', {
      uid: interaction.uid
      prompt: interaction.prompt
      params: interaction.params
      session: interaction.session
    }

    # Auto-approve for MCP Inspector testing
    userId = 'mcp-inspector-test-user'
    debug 'AUTO_APPROVE', { userId }

    result =
      login: accountId: userId
      consent:
        grantId: interaction.grantId

    debug 'INTERACTION_RESULT', { result }

    await provider.interactionFinished req, res, result,
      mergeWithLastSubmission: false

    debug 'INTERACTION_FINISHED', { uid: req.params.uid }

  catch error
    debug 'INTERACTION_ERROR', { 
      uid: req.params.uid
      error: error.message
      stack: error.stack
    }
    res.status(500).json error: error.message

# MCP-like protected endpoint
app.post '/api/mcp', verifyToken, (req, res) ->
  debug 'MCP_REQUEST', {
    user: req.user
    body: req.body
    headers: req.headers
  }
  
  res.json
    jsonrpc: '2.0'
    id: req.body.id
    result:
      message: 'MCP Inspector OAuth2 test successful!'
      user: req.user
      timestamp: new Date().toISOString()
      request: req.body

# Enhanced health check
app.get '/health', (req, res) ->
  debug 'HEALTH_CHECK', {}
  res.json
    status: 'ok'
    timestamp: new Date().toISOString()
    config:
      port: CONFIG.PORT
      issuer: CONFIG.ISSUER
      client_id: CONFIG.CLIENT_ID
      redirect_uri: CONFIG.REDIRECT_URI

# Enhanced error handler
app.use (err, req, res, next) ->
  debug 'EXPRESS_ERROR', {
    error: err.message
    stack: err.stack
    path: req.path
    method: req.method
  }
  res.status(500).json error: 'Internal server error'

# Start server with enhanced logging
app.listen CONFIG.PORT, ->
  debug 'SERVER_START', {
    port: CONFIG.PORT
    issuer: CONFIG.ISSUER
    client_id: CONFIG.CLIENT_ID
    redirect_uri: CONFIG.REDIRECT_URI
  }
  
  console.log """
  MCP Inspector OAuth2 Debug Server
  =================================
  Port: #{CONFIG.PORT}
  Issuer: #{CONFIG.ISSUER}
  Client ID: #{CONFIG.CLIENT_ID}
  Redirect URI: #{CONFIG.REDIRECT_URI}
  
  Endpoints:
  - Authorization: #{CONFIG.ISSUER}/oidc/auth
  - Token: #{CONFIG.ISSUER}/oidc/token
  - MCP API: #{CONFIG.ISSUER}/api/mcp
  - Health: #{CONFIG.ISSUER}/health
  
  Configure MCP Inspector with:
  - Authorization Server: #{CONFIG.ISSUER}
  - Client ID: #{CONFIG.CLIENT_ID}
  - Redirect URI: #{CONFIG.REDIRECT_URI}
  - Scopes: openid mcp read write
  """

module.exports = {app, provider}