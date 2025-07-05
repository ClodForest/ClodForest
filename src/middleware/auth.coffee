# FILENAME: { ClodForest/src/middleware/auth.coffee }
# OAuth2 authentication middleware using oidc-provider

{ createProvider } = require '../oauth/oidc-provider'
{ logger } = require '../lib/logger'

# Create provider instance for token introspection
issuer = process.env.ISSUER_URL or "http://localhost:#{process.env.PORT or 8080}"
provider = createProvider issuer

# OAuth2 authentication middleware
authenticate = (req, res, next) ->
  try
    # Extract Bearer token from Authorization header
    authHeader = req.headers.authorization
    unless authHeader?.startsWith('Bearer ')
      logger.oauth 'Missing or invalid Authorization header', {
        authorization: authHeader?.substring(0, 20) + '...' if authHeader
        method: req.method
        path: req.path
      }
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'Bearer token required'

    token = authHeader.substring(7) # Remove 'Bearer ' prefix
    
    logger.oauth 'Authentication attempt', {
      tokenPrefix: token.substring(0, 10) + '...'
      method: req.method
      path: req.path
    }

    # Use oidc-provider's token introspection
    # Create a mock request for introspection
    introspectionReq = {
      method: 'POST'
      url: '/oauth/introspect'
      headers: {
        'content-type': 'application/x-www-form-urlencoded'
      }
      body: {
        token: token
        token_type_hint: 'access_token'
      }
    }

    # Get AccessToken instance from provider
    AccessToken = provider.AccessToken
    tokenInstance = await AccessToken.find(token)
    
    unless tokenInstance
      logger.oauth 'Token not found', { tokenPrefix: token.substring(0, 10) + '...' }
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'The access token provided is expired, revoked, malformed, or invalid'

    # Check if token is expired
    if tokenInstance.isExpired
      logger.oauth 'Token expired', { 
        tokenPrefix: token.substring(0, 10) + '...'
        expiresAt: tokenInstance.expiresAt
      }
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'The access token provided is expired'

    logger.oauth 'Authentication successful', {
      tokenPrefix: token.substring(0, 10) + '...'
      clientId: tokenInstance.clientId
      scope: tokenInstance.scope
    }

    # Add token info to request object
    req.oauth = {
      token: tokenInstance
      client: { id: tokenInstance.clientId }
      scope: tokenInstance.scope
    }

    next()

  catch error
    logger.oauth 'Authentication error', {
      error: error.message
      stack: error.stack
      method: req.method
      path: req.path
    }

    # Handle specific error types
    if error.name is 'InvalidTokenError' or error.message?.includes('invalid')
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'The access token provided is expired, revoked, malformed, or invalid'

    # Generic authentication error
    res.status(401).json
      error: 'invalid_token'
      error_description: 'Authentication failed'

# Scope verification middleware factory
requireScope = (requiredScope) ->
  (req, res, next) ->
    unless req.oauth?.token
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'No valid token found'

    tokenScopes = if req.oauth.scope then req.oauth.scope.split(' ') else []
    requiredScopes = requiredScope.split ' '

    hasRequiredScope = requiredScopes.every (scope) -> tokenScopes.includes scope

    unless hasRequiredScope
      logger.oauth 'Insufficient scope', {
        required: requiredScope
        provided: req.oauth.scope
        clientId: req.oauth.client?.id
      }
      return res.status(403).json
        error: 'insufficient_scope'
        error_description: "Required scope: #{requiredScope}"

    next()

module.exports = authenticate
module.exports.requireScope = requireScope
