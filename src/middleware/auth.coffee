# FILENAME: { ClodForest/src/middleware/auth.coffee }
# OAuth2 authentication middleware using JWT validation

{ jwtVerify, createRemoteJWKSet } = require 'jose'
{ logger } = require '../lib/logger'

# Dynamic JWKS endpoint for JWT verification
getDynamicJwksUri = (req) ->
  # Handle AWS ALB/CloudFront forwarded headers
  protocol = req.get('X-Forwarded-Proto') or req.protocol or 'http'
  host = req.get('X-Forwarded-Host') or req.get('host') or "localhost:#{process.env.PORT or 8080}"
  issuer = "#{protocol}://#{host}/oauth"
  "#{issuer}/jwks"

# Cache JWKS clients to avoid creating new ones for each request
jwksCache = new Map()

# OAuth2 authentication middleware - smart path-based protection
authenticate = (req, res, next) ->
  try
    # Paths that require authentication
    protectedPaths = [
      '/api/mcp'
    ]
    
    # Paths that are explicitly public
    publicPaths = [
      '/api/health'
      '/oauth'
      '/.well-known'
      '/'
    ]
    
    # Check if this path needs authentication
    needsAuth = protectedPaths.some (path) -> req.path.startsWith(path)
    isPublic = publicPaths.some (path) -> req.path.startsWith(path)
    
    # Debug log
    logger.oauth 'Auth middleware called', {
      method: req.method
      url: req.url
      originalUrl: req.originalUrl
      path: req.path
      needsAuth: needsAuth
      isPublic: isPublic
      ip: req.ip
      userAgent: req.get('User-Agent')
    }
    
    # If path doesn't need auth, pass through
    if isPublic or not needsAuth
      return next()
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

    # Validate JWT token using JWKS (RFC 7519)
    # This is the proper way for a resource server to validate JWT tokens
    try
      # Get dynamic JWKS and issuer for this request
      jwksUri = getDynamicJwksUri(req)
      protocol = req.get('X-Forwarded-Proto') or req.protocol or 'http'
      host = req.get('X-Forwarded-Host') or req.get('host') or "localhost:#{process.env.PORT or 8080}"
      issuer = "#{protocol}://#{host}/oauth"
      audience = "#{protocol}://#{host}/api/mcp"
      
      # Get or create JWKS client for this URI
      unless jwksCache.has(jwksUri)
        jwksCache.set(jwksUri, createRemoteJWKSet(new URL(jwksUri)))
      JWKS = jwksCache.get(jwksUri)
      
      # Verify JWT signature, expiry, and claims
      { payload } = await jwtVerify token, JWKS, {
        issuer: issuer
        audience: audience
      }

      logger.oauth 'JWT validation successful', {
        tokenPrefix: token.substring(0, 10) + '...'
        clientId: payload.client_id
        scope: payload.scope
        audience: payload.aud
        subject: payload.sub
      }

      # Add token info to request object
      req.oauth = {
        payload: payload
        client: { id: payload.client_id }
        scope: payload.scope
      }

    catch error
      logger.oauth 'JWT validation failed', { 
        error: error.message
        tokenPrefix: token.substring(0, 10) + '...'
        errorCode: error.code
      }
      
      return res.status(401).json
        error: 'invalid_token'
        error_description: 'The access token provided is expired, revoked, malformed, or invalid'

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
    unless req.oauth?.payload
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
