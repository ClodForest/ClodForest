# FILENAME: { ClodForest/src/coordinator/lib/oauth2/index.coffee }
# OAuth2 Server Implementation for ClodForest
# Provides OAuth2 authentication for MCP and other protected endpoints

crypto = require 'crypto'
config = require '../config'

# In-memory stores (replace with database in production)
clients     = new Map()
tokens      = new Map()
authCodes   = new Map()

# Token expiration times
ACCESS_TOKEN_TTL  = 3600     # 1 hour
REFRESH_TOKEN_TTL = 2592000  # 30 days
AUTH_CODE_TTL     = 600      # 10 minutes

# Generate secure random tokens
generateToken = ->
  crypto.randomBytes(32).toString('hex')

# Generate token with metadata
createToken = (clientId, userId, scope) ->
  token =
    accessToken:  generateToken()
    tokenType:    'Bearer'
    expiresIn:    ACCESS_TOKEN_TTL
    scope:        scope
    clientId:     clientId
    userId:       userId
    createdAt:    Date.now()
  
  # Only include refresh token for authorization code grant (when userId is present)
  # Per RFC 6749 Section 4.4.3, client credentials grant should not include refresh token
  if userId
    token.refreshToken = generateToken()
  
  # Store access token
  tokens.set token.accessToken, {
    ...token
    type: 'access'
    expiresAt: Date.now() + (ACCESS_TOKEN_TTL * 1000)
  }
  
  # Store refresh token only if it exists
  if token.refreshToken
    tokens.set token.refreshToken, {
      ...token
      type: 'refresh'
      expiresAt: Date.now() + (REFRESH_TOKEN_TTL * 1000)
    }
  
  token

# Register a client application
registerClient = (clientData) ->
  client =
    clientId:     crypto.randomBytes(16).toString('hex')
    clientSecret: crypto.randomBytes(32).toString('hex')
    name:         clientData.name
    redirectUris: clientData.redirectUris or []
    scope:        clientData.scope or 'read'
    createdAt:    Date.now()
  
  clients.set client.clientId, client
  client

# Validate client credentials
validateClient = (clientId, clientSecret) ->
  client = clients.get(clientId)
  return null unless client
  return null unless client.clientSecret is clientSecret
  client

# Create authorization code
createAuthCode = (clientId, userId, redirectUri, scope) ->
  code = generateToken()
  
  authCodes.set code, {
    clientId:    clientId
    userId:      userId
    redirectUri: redirectUri
    scope:       scope
    createdAt:   Date.now()
    expiresAt:   Date.now() + (AUTH_CODE_TTL * 1000)
  }
  
  code

# Exchange authorization code for tokens
exchangeAuthCode = (code, clientId, redirectUri) ->
  authCode = authCodes.get(code)
  
  # Validate code
  return error: 'invalid_grant' unless authCode
  return error: 'invalid_grant' if authCode.expiresAt < Date.now()
  return error: 'invalid_client' if authCode.clientId isnt clientId
  return error: 'invalid_grant' if authCode.redirectUri isnt redirectUri
  
  # Remove used code
  authCodes.delete code
  
  # Create tokens
  createToken clientId, authCode.userId, authCode.scope

# Refresh access token
refreshAccessToken = (refreshToken, clientId) ->
  token = tokens.get(refreshToken)
  
  # Validate refresh token
  return error: 'invalid_grant' unless token
  return error: 'invalid_grant' if token.type isnt 'refresh'
  return error: 'invalid_grant' if token.expiresAt < Date.now()
  return error: 'invalid_client' if token.clientId isnt clientId
  
  # Delete old tokens
  tokens.delete token.accessToken
  tokens.delete refreshToken
  
  # Create new tokens
  createToken clientId, token.userId, token.scope

# Validate access token
validateAccessToken = (accessToken) ->
  token = tokens.get(accessToken)
  
  # Check token exists and is valid
  return null unless token
  return null if token.type isnt 'access'
  return null if token.expiresAt < Date.now()
  
  token

# Clean up expired tokens
cleanupExpiredTokens = ->
  now = Date.now()
  
  # Clean up tokens
  tokens.forEach (token, key) ->
    if token.expiresAt < now
      tokens.delete key
  
  # Clean up auth codes
  authCodes.forEach (authCode, code) ->
    if authCode.expiresAt < now
      authCodes.delete code

# Run cleanup every 5 minutes
setInterval cleanupExpiredTokens, 5 * 60 * 1000

# Export OAuth2 interface
module.exports = {
  registerClient
  validateClient
  createAuthCode
  exchangeAuthCode
  refreshAccessToken
  validateAccessToken
  createToken
  
  # For testing
  _stores: { clients, tokens, authCodes }
}
