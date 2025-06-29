# FILENAME: { ClodForest/src/coordinator/handlers/oauth.coffee }
# OAuth2 Endpoint Handlers
# Implements OAuth2 authorization and token endpoints

oauth2 = require '../lib/oauth2'
config = require '../lib/config'

# Simple in-memory user store (replace with proper user management)
users = new Map([
  ['admin', { id: 'admin', password: 'admin', name: 'Administrator' }]
])

# Validate user credentials
validateUser = (username, password) ->
  user = users.get(username)
  return null unless user
  return null unless user.password is password
  user

# Authorization endpoint - GET /oauth/authorize
authorize = (req, res) ->
  {client_id, redirect_uri, response_type, scope, state} = req.query
  
  # Validate parameters
  unless client_id and redirect_uri and response_type is 'code'
    return res.status(400).json
      error: 'invalid_request'
      error_description: 'Missing or invalid parameters'
  
  # Validate client
  # Note: In production, validate client_id and redirect_uri
  
  # For demo purposes, show a simple login form
  html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>ClodForest OAuth2 Login</title>
      <style>
        body { 
          font-family: monospace; 
          margin: 40px auto; 
          max-width: 400px;
          background: #1a1a1a; 
          color: #00ff00; 
        }
        .container {
          background: #222;
          padding: 30px;
          border: 1px solid #00ff00;
        }
        h1 { color: #00ffff; }
        input { 
          width: 100%; 
          padding: 8px; 
          margin: 8px 0;
          background: #333;
          color: #00ff00;
          border: 1px solid #00ff00;
        }
        button { 
          background: #00ff00;
          color: #000;
          padding: 10px 20px;
          border: none;
          cursor: pointer;
          width: 100%;
          margin-top: 10px;
        }
        button:hover { background: #00cc00; }
        .error { color: #ff0000; margin: 10px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🔐 ClodForest Login</h1>
        <p>Authorize access to your ClodForest resources</p>
        <form method="POST" action="/oauth/authorize">
          <input type="hidden" name="client_id" value="#{client_id}">
          <input type="hidden" name="redirect_uri" value="#{redirect_uri}">
          <input type="hidden" name="response_type" value="#{response_type}">
          <input type="hidden" name="scope" value="#{scope or 'read'}">
          <input type="hidden" name="state" value="#{state or ''}">
          
          <input type="text" name="username" placeholder="Username" required>
          <input type="password" name="password" placeholder="Password" required>
          
          <button type="submit">Authorize</button>
        </form>
        <p style="margin-top: 20px; font-size: 12px;">Demo credentials: admin/admin</p>
      </div>
    </body>
    </html>
  """
  
  res.send html

# Authorization endpoint - POST /oauth/authorize
authorizeSubmit = (req, res) ->
  {client_id, redirect_uri, response_type, scope, state, username, password} = req.body
  
  # Validate user credentials
  user = validateUser(username, password)
  unless user
    # Redirect back with error
    return res.redirect "/oauth/authorize?#{new URLSearchParams(req.body).toString()}&error=invalid_credentials"
  
  # Create authorization code
  code = oauth2.createAuthCode(client_id, user.id, redirect_uri, scope or 'read')
  
  # Build redirect URL
  redirectUrl = new URL(redirect_uri)
  redirectUrl.searchParams.set 'code', code
  redirectUrl.searchParams.set 'state', state if state
  
  res.redirect redirectUrl.toString()

# Token endpoint - POST /oauth/token
token = (req, res) ->
  {grant_type, code, redirect_uri, refresh_token} = req.body
  
  # Extract client credentials from Authorization header or body
  clientId = clientSecret = null
  
  authHeader = req.get('Authorization')
  if authHeader?.startsWith('Basic ')
    credentials = Buffer.from(authHeader.substring(6), 'base64').toString()
    [clientId, clientSecret] = credentials.split(':')
  else if req.body.client_id and req.body.client_secret
    {client_id: clientId, client_secret: clientSecret} = req.body
  
  unless clientId and clientSecret
    return res.status(401).json
      error: 'invalid_client'
      error_description: 'Client authentication failed'
  
  # Validate client
  client = oauth2.validateClient(clientId, clientSecret)
  unless client
    return res.status(401).json
      error: 'invalid_client'
      error_description: 'Client authentication failed'
  
  # Handle grant types
  result = switch grant_type
    when 'authorization_code'
      unless code and redirect_uri
        error: 'invalid_request'
      else
        oauth2.exchangeAuthCode(code, clientId, redirect_uri)
    
    when 'refresh_token'
      unless refresh_token
        error: 'invalid_request'
      else
        oauth2.refreshAccessToken(refresh_token, clientId)
    
    else
      error: 'unsupported_grant_type'
  
  # Return result
  if result.error
    res.status(400).json
      error: result.error
      error_description: result.error_description or 'The request is invalid'
  else
    res.json
      access_token:  result.accessToken
      token_type:    result.tokenType
      expires_in:    result.expiresIn
      refresh_token: result.refreshToken
      scope:         result.scope

# Client registration endpoint - POST /oauth/clients
registerClient = (req, res) ->
  {name, redirect_uris, scope} = req.body
  
  unless name and redirect_uris
    return res.status(400).json
      error: 'invalid_request'
      error_description: 'Missing required parameters'
  
  # Register the client
  client = oauth2.registerClient({
    name: name
    redirectUris: Array.isArray(redirect_uris) ? redirect_uris : [redirect_uris]
    scope: scope
  })
  
  res.status(201).json
    client_id:     client.clientId
    client_secret: client.clientSecret
    name:          client.name
    redirect_uris: client.redirectUris
    scope:         client.scope

module.exports = {
  authorize
  authorizeSubmit
  token
  registerClient
}
