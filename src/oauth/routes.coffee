# FILENAME: { ClodForest/src/oauth/routes.coffee }
# Centralized route registry for OAuth endpoints
# Routes are processed in order - most specific first!

{ createProvider } = require './oidc-provider'
{ logger }         = require '../lib/logger'

# Create OIDC provider instance with dynamic issuer detection
getDynamicIssuer = (req) ->
  # Handle AWS ALB/CloudFront forwarded headers
  protocol = req.get('X-Forwarded-Proto') or req.protocol or 'http'
  host = req.get('X-Forwarded-Host') or req.get('host') or "localhost:#{process.env.PORT or 8080}"
  "#{protocol}://#{host}/oauth"

# Use environment variable if set, otherwise determine dynamically
staticIssuer = process.env.ISSUER_URL or "http://localhost:#{process.env.PORT or 8080}/oauth"
provider = createProvider staticIssuer

# Main interaction handler
interactionHandler = (req, res) ->
  try
    details = await getInteractionDetails req, res
    logInteractionRequest req.params.uid, details

    if isMcpClient details
      await approveInteraction req, res, details
    else
      rejectNonMcpClient res

  catch error
    # Handle SessionNotFound errors gracefully - this happens when an interaction
    # UID has already been processed or expired
    if error.message is 'invalid_request' or error.name is 'SessionNotFound'
      logger.oauth 'Interaction session not found (likely already processed)', {
        uid: req.params.uid
        error: error.message
      }
      res.status(400).json
        error: 'invalid_request'
        error_description: 'Interaction session not found or already processed'
    else
      handleInteractionError req.params.uid, error, res

# Helper functions defined after first use
getInteractionDetails = (req, res) ->
  await provider.interactionDetails req, res

logInteractionRequest = (uid, details) ->
  logger.oauth 'Interaction requested', {
    uid:       uid
    client_id: details.params.client_id
    scope:     details.params.scope
    prompt:    details.prompt
    session:   details.session
  }

isMcpClient = (details) ->
  details.params.scope?.includes('mcp')

approveInteraction = (req, res, details) ->
  result = await createApprovalResult details

  logAutoApproval req.params.uid, details, result

  await provider.interactionFinished req, res, result, {
    mergeWithLastSubmission: true
  }

createApprovalResult = (details) ->
  # For OAuth2 authorization_code flow, we need to provide login and consent
  result = {}
  
  # If login is required, provide a subject (user ID)
  if details.prompt.name is 'login' or details.prompt.details?.missingOIDCScope or details.prompt.details?.missingOIDCClaims
    result.login = 
      accountId: 'mcp-user'  # Simple fixed user ID for MCP clients
  
  # Consent is required - grant the requested scopes using Grant object (proper oidc-provider way)
  if details.prompt.name is 'consent' or details.prompt.details?.missingOIDCScope or details.prompt.details?.missingResourceScopes
    # Create or find the Grant object and add missing scopes
    grantId = await handleGrantConsent details
    
    result.consent = 
      grantId: grantId
  
  result

# Handle Grant object creation and scope granting (following oidc-provider official example)
handleGrantConsent = (details) ->
  { prompt: { name, details: promptDetails }, params, session: { accountId } } = details
  
  grantId = details.grantId
  grant = null
  
  if grantId
    # Modifying existing grant in existing session
    grant = await provider.Grant.find grantId
  else
    # Establishing a new grant
    grant = new provider.Grant {
      accountId: accountId
      clientId: params.client_id
    }
  
  # Add missing OIDC scopes (the key part I was missing!)
  if promptDetails.missingOIDCScope
    grant.addOIDCScope promptDetails.missingOIDCScope.join(' ')
  
  # Add missing OIDC claims
  if promptDetails.missingOIDCClaims
    grant.addOIDCClaims promptDetails.missingOIDCClaims
  
  # Add missing resource scopes
  if promptDetails.missingResourceScopes
    for indicator, scope of promptDetails.missingResourceScopes
      grant.addResourceScope indicator, scope.join(' ')
  
  # Save the grant and return the grantId
  await grant.save()

logAutoApproval = (uid, details, result) ->
  logger.oauth 'Auto-approving MCP client interaction', {
    uid:       uid
    client_id: details.params.client_id
    scope:     details.params.scope
    prompt:    details.prompt
    result:    result
  }

rejectNonMcpClient = (res) ->
  res.status(400).json
    error:             'interaction_required'
    error_description: 'This authorization server only supports MCP clients'

handleInteractionError = (uid, error, res) ->
  logger.oauth 'Interaction error', {
    uid:   uid
    error: error.message
    stack: error.stack
  }

  res.status(500).json
    error:             'server_error'
    error_description: 'Internal server error during interaction'

# Route registry - processed in order (most specific first)
routeRegistry = [
  {
    path:        '/oauth/interaction/:uid'
    method:      'GET'
    handler:     interactionHandler
    description: 'Auto-approval interaction endpoint for MCP clients'
  }
  {
    path:        '/oauth'
    method:      'ALL'
    handler:     provider.callback()
    description: 'OIDC provider endpoints (catch-all)'
  }
]

# Route debugging helper
routeDebugger = (req, res, next) ->
  logger.oauth 'Route request', {
    method:      req.method
    path:        req.path
    url:         req.url
    originalUrl: req.originalUrl
  }
  next()

# Helper to register routes in order
registerRoutes = (router) ->
  logger.oauth 'Starting route registration'
  
  router.use routeDebugger
  logger.oauth 'Route debugger middleware added'
  
  for route in routeRegistry
    try
      methodName = route.method.toLowerCase()
      
      if methodName is 'all'
        router.use route.path, route.handler
      else
        router[methodName] route.path, route.handler
      
      logger.oauth 'Route registered', {
        method:      route.method
        path:        route.path
        description: route.description
      }
    catch error
      logger.oauth 'Route registration error', {
        route: route
        error: error.message
      }
  
  logger.oauth 'Route registration completed'

module.exports = { registerRoutes }