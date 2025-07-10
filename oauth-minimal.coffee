# Minimal OAuth2 Implementation with Express5 and oidc-provider
# Dependencies: express@5, oidc-provider, jose, coffeescript

express              = require 'express'
{Provider}           = require 'oidc-provider'
{SignJWT, jwtVerify} = require 'jose'
crypto               = require 'crypto'
eath                 = require 'path'

CONFIG =
  PORT:          process.env.PORT          or 3000
  ISSUER:        process.env.ISSUER        or "http://localhost:#{process.env.PORT or 3000}"
  SECRET_KEY:    process.env.SECRET_KEY    or crypto.randomBytes 32
  CLIENT_ID:     process.env.CLIENT_ID     or 'minimal-client'
  CLIENT_SECRET: process.env.CLIENT_SECRET or 'minimal-secret'
  REDIRECT_URI:  process.env.REDIRECT_URI  or "http://localhost:#{process.env.PORT or 3000}/callback"

oidcConfig =
  clients: [
    client_id:     CONFIG.CLIENT_ID
    client_secret: CONFIG.CLIENT_SECRET
    redirect_uris: [CONFIG.REDIRECT_URI]
    grant_types:   ['authorization_code']
    response_types: ['code']
    scope:         'openid profile'
  ]

  # Minimal interaction - auto-approve for demo
  interactions:
    url: (ctx, interaction) ->
      "/interaction/#{interaction.uid}"

  # Simple in-memory account store
  findAccount: (ctx, id) ->
    accountId: id
    claims: ->
      sub:   id
      name:  "User #{id}"
      email: "user#{id}@example.com"

  features:
    devInteractions: enabled: false

app      = express()
provider = new Provider CONFIG.ISSUER, oidcConfig

app.use express.json()
app.use express.urlencoded extended: true

app.use '/oidc', provider.callback()

verifyToken = (req, res, next) ->
  authHeader = req.headers.authorization

  unless authHeader?.startsWith 'Bearer '
    return res.status(401).json error: 'Missing or invalid authorization header'

  token = authHeader.substring 7

  try
    secret = new TextEncoder().encode CONFIG.SECRET_KEY
    {payload} = await jwtVerify token, secret

    req.user = payload
    next()
  catch error
    res.status(401).json error: 'Invalid token'

app.get '/', (req, res) ->
  res.json
    message: 'Minimal OAuth2 Server'
    endpoints:
      authorization: "#{CONFIG.ISSUER}/oidc/auth"
      token:         "#{CONFIG.ISSUER}/oidc/token"
      userinfo:      "#{CONFIG.ISSUER}/oidc/me"
      protected_api: "#{CONFIG.ISSUER}/api/hello"
    client:
      client_id:     CONFIG.CLIENT_ID
      redirect_uri:  CONFIG.REDIRECT_URI
      scope:         'openid profile'

# Authorization endpoint - redirect to OIDC provider
app.get '/auth', (req, res) ->
  params = new URLSearchParams
    response_type: 'code'
    client_id:     CONFIG.CLIENT_ID
    redirect_uri:  CONFIG.REDIRECT_URI
    scope:         'openid profile'
    state:         crypto.randomBytes(16).toString('hex')

  res.redirect "#{CONFIG.ISSUER}/oidc/auth?#{params}"

# Callback handler - exchange code for token
app.get '/callback', (req, res) ->
  {code, state} = req.query

  unless code
    return res.status(400).json error: 'Missing authorization code'

  try
    # Exchange code for token
    tokenResponse = await fetch "#{CONFIG.ISSUER}/oidc/token",
      method: 'POST'
      headers: 'Content-Type': 'application/x-www-form-urlencoded'
      body: new URLSearchParams
        grant_type:    'authorization_code'
        client_id:     CONFIG.CLIENT_ID
        client_secret: CONFIG.CLIENT_SECRET
        code:          code
        redirect_uri:  CONFIG.REDIRECT_URI

    tokens = await tokenResponse.json()

    unless tokenResponse.ok
      throw new Error tokens.error or 'Token exchange failed'

    # Return tokens (in production, handle more securely)
    res.json
      message: 'Authentication successful'
      tokens:  tokens
      api_url: "#{CONFIG.ISSUER}/api/hello"

  catch error
    res.status(500).json error: error.message

# Simple interaction handler for auto-approval
app.get '/interaction/:uid', (req, res) ->
  try
    interaction = await provider.interactionDetails req, res

    # Auto-approve for demo - assign user ID
    userId = 'demo-user-123'

    result =
      login: accountId: userId

    await provider.interactionFinished req, res, result,
      mergeWithLastSubmission: false

  catch error
    res.status(500).json error: error.message

# Protected API endpoint
app.get '/api/hello', verifyToken, (req, res) ->
  res.json
    message: 'Hello from protected API!'
    user:    req.user
    timestamp: new Date().toISOString()

# Health check
app.get '/health', (req, res) ->
  res.json
    status: 'ok'
    timestamp: new Date().toISOString()

# Error handler
app.use (err, req, res, next) ->
  console.error 'Error:', err
  res.status(500).json error: 'Internal server error'

# Start server
app.listen CONFIG.PORT, ->
  console.log "OAuth2 server running on port #{CONFIG.PORT}"
  console.log "Issuer: #{CONFIG.ISSUER}"
  console.log "Authorization URL: #{CONFIG.ISSUER}/auth"
  console.log "Protected API: #{CONFIG.ISSUER}/api/hello"

module.exports = {app, provider}
