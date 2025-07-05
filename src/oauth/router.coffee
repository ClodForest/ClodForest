# FILENAME: { ClodForest/src/oauth/router.coffee }
# OAuth2 router using oidc-provider

express = require 'express'
{ createProvider } = require './oidc-provider'
{ logger } = require '../lib/logger'

# Create router
router = express.Router()

# Create OIDC provider instance
issuer = process.env.ISSUER_URL or "http://localhost:#{process.env.PORT or 8080}"
provider = createProvider issuer

# Fix MCP Inspector's malformed grant_types before oidc-provider processes it
router.use (req, res, next) ->
  # Debug logging to see all requests
  if req.method is 'POST'
    logger.oauth 'POST request intercepted', {
      path: req.path
      url: req.url
      originalUrl: req.originalUrl
      body: req.body
    }
  
  if req.path is '/register' and req.method is 'POST' and req.body?.grant_types?.includes('refresh_token')
    originalGrantTypes = req.body.grant_types
    req.body.grant_types = originalGrantTypes.filter (gt) -> gt isnt 'refresh_token'
    
    logger.oauth 'Fixed MCP Inspector malformed grant_types', {
      original: originalGrantTypes
      fixed: req.body.grant_types
      note: 'refresh_token is not a grant type per RFC 7591'
    }
  
  next()

# Mount the OIDC provider at /oauth path
router.use '/oauth', provider.callback()

# Custom interaction endpoint for auto-approval
router.get '/oauth/interaction/:uid', (req, res) ->
  try
    # Get interaction details
    details = await provider.interactionDetails req, res
    
    logger.oauth 'Interaction requested', {
      uid: req.params.uid
      client_id: details.params.client_id
      scope: details.params.scope
    }
    
    # Auto-approve for MCP clients
    if details.params.scope?.includes('mcp')
      result = {
        consent: {
          grantId: details.grantId
        }
      }
      
      logger.oauth 'Auto-approving MCP client interaction', {
        uid: req.params.uid
        client_id: details.params.client_id
        scope: details.params.scope
      }
      
      await provider.interactionFinished req, res, result, {
        mergeWithLastSubmission: false
      }
    else
      # For non-MCP clients, return error (we don't have a UI)
      res.status(400).json
        error: 'interaction_required'
        error_description: 'This authorization server only supports MCP clients'
        
  catch error
    logger.oauth 'Interaction error', {
      uid: req.params.uid
      error: error.message
      stack: error.stack
    }
    
    res.status(500).json
      error: 'server_error'
      error_description: 'Internal server error during interaction'

module.exports = router
