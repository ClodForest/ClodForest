# FILENAME: { ClodForest/src/oauth/router.coffee }
# OAuth2 router using centralized route registry

express            = require 'express'
{ registerRoutes } = require './routes'
{ logger }         = require '../lib/logger'

# Create router
router = express.Router()
logger.oauth 'OAuth router created'

# Fix MCP Inspector's malformed grant_types before oidc-provider processes it
router.use (req, res, next) ->
  if req.method is 'POST'
    logger.oauth 'POST request intercepted', {
      path:        req.path
      url:         req.url
      originalUrl: req.originalUrl
      body:        req.body
    }

  if isRefreshTokenRegistration req
    fixMalformedGrantTypes req

  next()

logger.oauth 'OAuth middleware added'

# Register all OAuth routes in correct order
registerRoutes router
logger.oauth 'OAuth routes registration called'

# Helper functions defined after first use
isRefreshTokenRegistration = (req) ->
  req.path is '/oauth/register' and 
  req.method is 'POST' and 
  req.body?.grant_types?.includes('refresh_token')

fixMalformedGrantTypes = (req) ->
  originalGrantTypes   = req.body.grant_types
  req.body.grant_types = originalGrantTypes.filter (gt) -> gt isnt 'refresh_token'

  logger.oauth 'Fixed MCP Inspector malformed grant_types', {
    original: originalGrantTypes
    fixed:    req.body.grant_types
    note:     'refresh_token is not a grant type per RFC 7591'
  }

module.exports = router
