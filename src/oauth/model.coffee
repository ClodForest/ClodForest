# FILENAME: { ClodForest/src/oauth/model.coffee }
# OAuth2 data model with file system persistence

fs     = require 'node:fs/promises'
path   = require 'node:path'
crypto = require 'node:crypto'

class OAuth2Model
  constructor: ->
    @dataDir     = path.join process.cwd(), 'data', 'oauth2'
    @clientsFile = path.join @dataDir, 'clients.json'
    @tokensFile  = path.join @dataDir, 'tokens.json'
    @initialized = false

  init: ->
    return if @initialized
    
    try
      await fs.mkdir @dataDir, recursive: true
      
      # Initialize clients file if it doesn't exist
      try
        await fs.access @clientsFile
      catch
        await fs.writeFile @clientsFile, JSON.stringify([], null, 2)

      # Initialize tokens file if it doesn't exist
      try
        await fs.access @tokensFile
      catch
        await fs.writeFile @tokensFile, JSON.stringify([], null, 2)
      
      @initialized = true
      console.log 'OAuth2 data directory initialized successfully'
    catch error
      console.error 'Failed to initialize OAuth2 data directory:', error
      throw error

  loadClients: ->
    await @init()
    try
      data = await fs.readFile @clientsFile, 'utf8'
      JSON.parse data
    catch
      []

  saveClients: (clients) ->
    await @init()
    await fs.writeFile @clientsFile, JSON.stringify(clients, null, 2)

  loadTokens: ->
    await @init()
    try
      data = await fs.readFile @tokensFile, 'utf8'
      JSON.parse data
    catch
      []

  saveTokens: (tokens) ->
    await @init()
    await fs.writeFile @tokensFile, JSON.stringify(tokens, null, 2)

  # OAuth2 Server required methods

  getClient: (clientId, clientSecret) ->
    clients = await @loadClients()
    client  = clients.find (c) -> c.id is clientId
    
    return false unless client
    
    # If clientSecret is provided, verify it
    if clientSecret and client.secret isnt clientSecret
      return false

    id:           client.id
    grants:       client.grants or ['client_credentials']
    redirectUris: client.redirectUris or []
    scope:        client.scope or 'mcp read write'

  saveToken: (token, client, user) ->
    tokens = await @loadTokens()
    
    tokenData =
      accessToken:           token.accessToken
      accessTokenExpiresAt:  token.accessTokenExpiresAt
      refreshToken:          token.refreshToken
      refreshTokenExpiresAt: token.refreshTokenExpiresAt
      scope:                 token.scope
      client:                id: client.id
      user:                  user or null
      createdAt:             new Date().toISOString()

    tokens.push tokenData
    await @saveTokens tokens

    tokenData

  getAccessToken: (accessToken) ->
    tokens = await @loadTokens()
    token  = tokens.find (t) -> t.accessToken is accessToken
    
    return false unless token
    
    # Convert string dates back to Date objects (JSON serialization converts dates to strings)
    accessTokenExpiresAt = if token.accessTokenExpiresAt then new Date(token.accessTokenExpiresAt) else null
    
    # Check if token is expired
    if accessTokenExpiresAt and new Date() > accessTokenExpiresAt
      return false

    accessToken:          token.accessToken
    accessTokenExpiresAt: accessTokenExpiresAt  # Return as Date object
    scope:                token.scope
    client:               token.client
    user:                 token.user

  verifyScope: (token, scope) ->
    return false unless token.scope
    
    tokenScopes    = token.scope.split ' '
    requiredScopes = scope.split ' '
    
    requiredScopes.every (s) -> tokenScopes.includes s

  getUserFromClient: (client) ->
    # For client_credentials grant, return a simple user object
    # since this is machine-to-machine authentication
    id:       'system'
    username: client.id

  # Client registration method
  registerClient: (clientData) ->
    clients = await @loadClients()
    
    client =
      id:           crypto.randomUUID()
      secret:       crypto.randomBytes(32).toString('hex')
      name:         clientData.client_name or 'Unnamed Client'
      grants:       clientData.grant_types or ['client_credentials']
      redirectUris: clientData.redirect_uris or []
      scope:        clientData.scope or 'mcp read write'
      createdAt:    new Date().toISOString()

    clients.push client
    await @saveClients clients

    client

  # Clean up expired tokens
  cleanupExpiredTokens: ->
    tokens = await @loadTokens()
    now    = new Date()
    
    validTokens = tokens.filter (token) ->
      return true unless token.accessTokenExpiresAt
      new Date(token.accessTokenExpiresAt) > now

    if validTokens.length isnt tokens.length
      await @saveTokens validTokens
      console.log "Cleaned up #{tokens.length - validTokens.length} expired tokens"

module.exports = OAuth2Model
