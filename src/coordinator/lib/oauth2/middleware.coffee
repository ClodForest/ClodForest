# FILENAME: { ClodForest/src/coordinator/lib/oauth2/middleware.coffee }
# OAuth2 Middleware
# Protects endpoints with OAuth2 authentication

oauth2 = require './index'

# Extract token from request
extractToken = (req) ->
  # Check Authorization header
  authHeader = req.get('Authorization')
  if authHeader?.startsWith('Bearer ')
    return authHeader.substring(7)
  
  # Check query parameter (not recommended for production)
  if req.query.access_token
    return req.query.access_token
  
  null

# Middleware to require OAuth2 authentication
requireAuth = (requiredScope = null) ->
  (req, res, next) ->
    token = extractToken(req)
    
    unless token
      return res.status(401).json
        error: 'unauthorized'
        error_description: 'Access token required'
    
    # Validate token
    tokenData = oauth2.validateAccessToken(token)
    unless tokenData
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'The access token is invalid or expired'
    
    # Check scope if required
    if requiredScope
      tokenScopes = tokenData.scope?.split(' ') or []
      unless requiredScope in tokenScopes
        return res.status(403).json
          error: 'insufficient_scope'
          error_description: "This request requires '#{requiredScope}' scope"
    
    # Attach token data to request
    req.oauth = tokenData
    next()

# Optional OAuth2 authentication (doesn't fail if no token)
optionalAuth = ->
  (req, res, next) ->
    token = extractToken(req)
    
    if token
      tokenData = oauth2.validateAccessToken(token)
      req.oauth = tokenData if tokenData
    
    next()

module.exports = {
  requireAuth
  optionalAuth
  extractToken
}
