# FILENAME: { ClodForest/src/oauth/oidc-provider.coffee }
# OIDC Provider configuration for OAuth2 server

Provider = require('oidc-provider').Provider
path     = require 'node:path'
fs       = require 'node:fs/promises'
{ logger } = require '../lib/logger'

# Data directory for persistence
DATA_DIR = path.join process.cwd(), 'data', 'oauth2'

# File-based adapter for oidc-provider
class FileAdapter
  constructor: (@name) ->
    @dataFile = path.join DATA_DIR, "#{@name}.json"
    @init()

  init: ->
    try
      await fs.mkdir DATA_DIR, recursive: true
      try
        await fs.access @dataFile
      catch
        await fs.writeFile @dataFile, JSON.stringify({}, null, 2)
    catch error
      logger.error "Failed to initialize #{@name} storage", { error: error.message }

  loadData: ->
    try
      data = await fs.readFile @dataFile, 'utf8'
      JSON.parse data
    catch
      {}

  saveData: (data) ->
    await fs.writeFile @dataFile, JSON.stringify(data, null, 2)

  upsert: (id, payload, expiresIn) ->
    data = await @loadData()
    
    # Calculate expiration if provided
    expiresAt = if expiresIn then new Date(Date.now() + expiresIn * 1000) else null
    
    data[id] = {
      payload: payload
      expiresAt: expiresAt?.toISOString()
      createdAt: new Date().toISOString()
    }
    
    await @saveData data
    undefined

  find: (id) ->
    data = await @loadData()
    record = data[id]
    
    return undefined unless record
    
    # Check if expired
    if record.expiresAt and new Date() > new Date(record.expiresAt)
      delete data[id]
      await @saveData data
      return undefined
    
    record.payload

  findByUserCode: (userCode) ->
    data = await @loadData()
    for id, record of data
      if record.payload?.userCode is userCode
        return @find id
    undefined

  findByUid: (uid) ->
    data = await @loadData()
    for id, record of data
      if record.payload?.uid is uid
        return @find id
    undefined

  consume: (id) ->
    data = await @loadData()
    record = data[id]
    return undefined unless record
    
    record.payload.consumed = Math.floor(Date.now() / 1000)
    await @saveData data
    undefined

  destroy: (id) ->
    data = await @loadData()
    delete data[id]
    await @saveData data
    undefined

  revokeByGrantId: (grantId) ->
    data = await @loadData()
    toDelete = []
    
    for id, record of data
      if record.payload?.grantId is grantId
        toDelete.push id
    
    for id in toDelete
      delete data[id]
    
    await @saveData data if toDelete.length > 0
    undefined

# OIDC Provider configuration
configuration =
  # OAuth2-only mode (disable OpenID Connect features we don't need)
  features:
    devInteractions:
      enabled: false
    clientCredentials:
      enabled: true
    introspection:
      enabled: true
    revocation:
      enabled: true
    registration:
      enabled: true
      initialAccessToken: false

  # Supported grant types (include refresh_token for MCP Inspector compatibility)
  grantTypes: [
    'authorization_code'
    'client_credentials'
    'refresh_token'
  ]

  # Client defaults to handle MCP Inspector's grant_types validation
  clientDefaults:
    grant_types: ['authorization_code']
    response_types: ['code']
    token_endpoint_auth_method: 'client_secret_basic'

  # Extra client metadata validation to handle refresh_token filtering
  extraClientMetadata:
    properties: ['grant_types']
    validator: (ctx, key, value, metadata) ->
      # Custom validation for grant_types to filter refresh_token
      if key is 'grant_types' and Array.isArray(value)
        # Filter out refresh_token from the grant_types array since it's not a valid grant type for registration
        # refresh_token capability is automatically available with authorization_code
        filtered = value.filter (gt) -> gt isnt 'refresh_token'
        if filtered.length isnt value.length
          logger.oauth 'Filtering refresh_token from grant_types during registration', {
            original: value
            filtered: filtered
            note: 'refresh_token is automatically available with authorization_code grant'
          }
          # Modify the metadata directly
          metadata.grant_types = filtered
        return
      
      # Default validation for other properties
      return

  # Supported response types
  responseTypes: [
    'code'
  ]

  # Token lifetimes
  ttl:
    AccessToken: 3600        # 1 hour
    AuthorizationCode: 300   # 5 minutes
    RefreshToken: 86400      # 24 hours
    ClientCredentials: 3600  # 1 hour

  # Scopes
  scopes: ['mcp', 'read', 'write']

  # Claims (minimal for OAuth2-only)
  claims:
    openid: []

  # Client authentication methods
  clientAuthMethods: [
    'client_secret_basic'
    'client_secret_post'
    'none'  # For public clients
  ]

  # PKCE configuration
  pkce:
    methods: ['S256']
    required: (ctx, client) ->
      # Require PKCE for public clients
      client.clientAuthMethod is 'none'

  # Custom adapter for file-based storage
  adapter: (name) -> new FileAdapter(name)

  # Custom client lookup for our file-based storage
  findAccount: (ctx, sub) ->
    # Simple account for OAuth2 (not used in client_credentials flow)
    accountId: sub
    claims: -> {}

  # Interaction handling (simplified for OAuth2)
  interactions:
    url: (ctx, interaction) ->
      # For authorization_code flow, auto-approve for MCP clients
      "/oauth/interaction/#{interaction.uid}"

  # Custom routes (relative to mount point)
  routes:
    authorization: '/authorize'
    token: '/token'
    introspection: '/introspect'
    revocation: '/revoke'
    registration: '/register'

  # Error handling
  renderError: (ctx, out, error) ->
    logger.oauth 'OIDC Provider Error', {
      error: error.error
      description: error.error_description
      status: error.status
    }
    
    ctx.type = 'application/json'
    ctx.body = {
      error: error.error
      error_description: error.error_description
    }

# Create and configure the provider
createProvider = (issuer) ->
  provider = new Provider issuer, configuration
  
  # Event listeners for logging
  provider.on 'grant.success', (ctx) ->
    logger.oauth 'Grant successful', {
      grant_type: ctx.oidc.params.grant_type
      client_id: ctx.oidc.client?.clientId
      scope: ctx.oidc.params.scope
    }

  provider.on 'grant.error', (ctx, error) ->
    logger.oauth 'Grant error', {
      error: error.message
      grant_type: ctx.oidc.params.grant_type
      client_id: ctx.oidc.client?.clientId
    }

  provider.on 'registration.success', (ctx, client) ->
    logger.oauth 'Client registration successful', {
      client_id: client.clientId
      client_name: client.clientName
      grant_types: client.grantTypes
    }

  provider.on 'registration.error', (ctx, error) ->
    logger.oauth 'Client registration error', {
      error: error.message
      client_name: ctx.request.body?.client_name
    }

  # Fix MCP Inspector's grant_types before oidc-provider validation
  provider.use (ctx, next) ->
    if ctx.path is '/register' and ctx.method is 'POST'
      # MCP Inspector sends refresh_token in grant_types, but oidc-provider only allows
      # authorization_code or client_credentials. Filter it out since refresh_token
      # capability is automatically available with authorization_code.
      if ctx.request.body?.grant_types?.includes('refresh_token')
        originalGrantTypes = ctx.request.body.grant_types
        ctx.request.body.grant_types = originalGrantTypes.filter (gt) -> gt isnt 'refresh_token'
        
        logger.oauth 'Fixed MCP Inspector grant_types for oidc-provider compatibility', {
          original: originalGrantTypes
          fixed: ctx.request.body.grant_types
          note: 'refresh_token capability is automatically available with authorization_code'
        }
    
    await next()

  # Handle authorization endpoint for auto-approval
  provider.use (ctx, next) ->
    if ctx.path is '/oauth/authorize' and ctx.method is 'GET'
      # Auto-approve authorization requests for MCP clients
      try
        # Get the interaction
        details = await provider.interactionDetails(ctx.req, ctx.res)
        
        # Auto-grant for MCP scope
        if details.params.scope?.includes('mcp')
          result = {
            consent: {
              grantId: details.grantId
            }
          }
          
          await provider.interactionFinished(ctx.req, ctx.res, result, {
            mergeWithLastSubmission: false
          })
          return
      catch error
        logger.oauth 'Auto-approval error', { error: error.message }
    
    await next()

  provider

module.exports = { createProvider, FileAdapter }
