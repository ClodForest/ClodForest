# ClodForest Routing Module
# All route definitions and handlers

express = require 'express'
apis    = require './apis'
config  = require './config'

# Setup function to apply all routes to app

setup = (app) ->
  # Welcome page - serves as API documentation and status
  app.get '/', (req, res) ->

    welcomeData = apis.getWelcomeData()

    if req.get('Accept')?.includes('text/html')
      # Serve HTML welcome page

      html = """

      <!DOCTYPE html>
      <html>
      <head>
        <title>#{config.SERVICE_NAME}</title>
        <style>
          body { font-family: monospace; margin: 40px; background: #1a1a1a; color: #00ff00; }
          .header { color: #00ffff; font-size: 24px; margin-bottom: 20px; }
          .status { color: #00ff00; }
          .endpoint { color: #ffff00; margin: 5px 0; }
          .feature { color: #ffffff; margin: 3px 0; }
          a { color: #00ffff; }
        </style>
      </head>
      <body>
        <div class="header">🔗 #{config.SERVICE_NAME}</div>
        <div class="status">Status: #{welcomeData.status}</div>
        <div class="status">Version: #{welcomeData.version}</div>
        <br>
        <div>API Endpoints:</div>
        <div class="endpoint">• <a href="#{config.API_PATHS.HEALTH}/">#{config.API_PATHS.HEALTH}/</a> - Service health check</div>
        <div class="endpoint">• <a href="#{config.API_PATHS.TIME}/">#{config.API_PATHS.TIME}/</a> - Time synchronization</div>
        <div class="endpoint">• <a href="#{config.API_PATHS.CONFIG}/">#{config.API_PATHS.CONFIG}/</a> - Configuration information</div>
        <div class="endpoint">• <a href="#{config.API_PATHS.REPO}">#{config.API_PATHS.REPO}</a> - Repository listing</div>
        <div class="endpoint">• <a href="#{config.API_PATHS.ADMIN}">#{config.API_PATHS.ADMIN}</a> - Administrative interface</div>
        <br>
        <div>Features:</div>
        #{welcomeData.features.map((f) -> "<div class=\"feature\">• #{f}</div>").join('')}
        <br>
        <div>Format: Add <code>Accept: application/json</code> header for JSON, defaults to YAML</div>
      </body>
      </html>
      """
      res.send html
    else
      app.formatResponse req, res, welcomeData

  # Time service for instance synchronization
  app.get config.API_PATHS.TIME + '/{*splat}', (req, res) ->
    timeData = apis.getTimeData(req)

    app.formatResponse req, res, timeData

  # Repository operations
  app.get config.API_PATHS.REPO, (req, res) ->
    repoData = apis.getRepositoryData()

    app.formatResponse req, res, repoData

  # Cache busting work-around
  app.get config.API_PATHS.BUSTIT + "/:trash/{*splat}", (req, res) ->
    realPath = req.params.splat.join "/"
    {trash} = req.params

    cacheBustingData =

      busted      : true
      originalPath: realPath
      timestamp   : new Date().toISOString()
      message     : "Busted dat cache"

    app.formatResponse req, res, bustData

  # Health check endpoint
  app.get config.API_PATHS.HEALTH + '/{*splat}', (req, res) ->

    healthData = apis.getHealthData()

    app.formatResponse req, res, healthData

  # Configuration endpoint
  app.get config.API_PATHS.CONFIG + '/{*splat}', (req, res) ->

    configData = apis.getConfigData()

    app.formatResponse req, res, configData

  # Browse repository contents
  app.get config.API_PATHS.REPO + '/:repo', (req, res) ->
    {repo} = req.params

    browsePath = req.query.path or ''
    browseData = apis.browseRepository(repo, browsePath)

    app.formatResponse req, res, browseData

  # Get file contents
  app.get config.API_PATHS.REPO + '/:repo/file/{*splat}', (req, res) ->
    {repo} = req.params

    filePath = req.params.splat.join "/"
    fileData = apis.readRepositoryFile(repo, filePath)

    app.formatResponse req, res, fileData

  # Git operations
  if config.FEATURES.GIT_OPERATIONS
    app.post config.API_PATHS.REPO + '/:repo/git/:command', (req, res) ->
      {repo, command} = req.params
      {args = []} = req.body

      apis.executeGitCommand repo, command, args, (gitData) ->
        app.formatResponse req, res, gitData

  # Context update endpoint
  if config.FEATURES.CONTEXT_UPDATES
    app.post config.API_PATHS.CONTEXT + '/update', (req, res) ->

      updateData = apis.processContextUpdate(req)

      app.formatResponse req, res, updateData

  # Instance coordination
  if config.FEATURES.INSTANCE_TRACKING
    app.get config.API_PATHS.INSTANCES, (req, res) ->

      instanceData = apis.getInstancesData()

      app.formatResponse req, res, instanceData

    app.post config.API_PATHS.INSTANCES + '/register', (req, res) ->
      apis.registerInstance(req.body)
      res.json status: 'registered', timestamp: new Date().toISOString()

  # MCP Protocol endpoint
  if config.FEATURES.MCP_PROTOCOL
    mcp = require '../handlers/mcp'
    
    # Apply OAuth2 protection if enabled
    if config.FEATURES.OAUTH2_AUTH
      {requireAuth} = require './oauth2/middleware'
      app.post config.API_PATHS.MCP, requireAuth('mcp'), (req, res) ->
        mcp.handleRequest req, res
    else
      app.post config.API_PATHS.MCP, (req, res) ->
        mcp.handleRequest req, res

  # OAuth2 endpoints
  if config.FEATURES.OAUTH2_AUTH
    oauth = require '../handlers/oauth'
    
    # OAuth2 authorization endpoints
    app.get  config.API_PATHS.OAUTH + '/authorize', oauth.authorize
    app.post config.API_PATHS.OAUTH + '/authorize', oauth.authorizeSubmit
    
    # OAuth2 token endpoint
    app.post config.API_PATHS.OAUTH + '/token', oauth.token
    
    # Client registration endpoint (in development only)
    if config.isDevelopment
      app.post config.API_PATHS.OAUTH + '/clients', oauth.registerClient

  # Admin interface
  app.get config.API_PATHS.ADMIN, (req, res) ->
    # In development mode, bypass authentication
    if config.FEATURES.ADMIN_AUTH and config.isProduction
      # TODO: Implement proper authentication
      return res.status(401).json error: 'Authentication required'

    html = apis.generateAdminHTML()

    res.send html

  # Static file serving for repository browsing
  app.use '/static', express.static(config.REPO_PATH)

  # 404 handler
  app.use (req, res) ->
    res.status(404).json
      error    : 'Not Found'
      path     : req.path
      timestamp: new Date().toISOString()

  # Error handler
  app.use (err, req, res, next) ->
    console.error 'Error:', err.message
    res.status(500).json
      error    : 'Internal Server Error'
      message  : err.message if config.isDevelopment
      timestamp: new Date().toISOString()

module.exports = { setup }
