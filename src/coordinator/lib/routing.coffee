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
      res.send """
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
          #{
            #<div class="endpoint">• <a href="#{config.API_PATHS.HEALTH}/">#{config.API_PATHS.HEALTH}/</a> - Service health check</div>
            #<div class="endpoint">• <a href="#{config.API_PATHS.TIME}/">#{config.API_PATHS.TIME}/</a> - Time synchronization</div>
            #<div class="endpoint">• <a href="#{config.API_PATHS.REPO}">#{config.API_PATHS.REPO}</a> - Repository listing</div>
            #<div class="endpoint">• <a href="#{config.API_PATHS.ADMIN}">#{config.API_PATHS.ADMIN}</a> - Administrative interface</div>
            for path, handler of config.API_PATHS
              { description = ''
              } = handler
              #{
                """<div class="endpoint">• <a href="#{path}">#{path}</a> - #{description}</div>"""
              #}

          }
          <br>
          <div>Features:</div>
          #{welcomeData.features.map((f) -> "<div class=\"feature\">• #{f}</div>").join('')}
          <br>
          <div>Format: Add <code>Accept: application/json</code> header for JSON, defaults to YAML</div>
        </body>
        </html>
      """
    else
      app.formatResponse req, res, welcomeData

  # Time service for instance synchronization
  app.get config.API_PATHS.TIME + '/{*splat}', require('./handlers/time')

  # Repository operations
  app.get config.API_PATHS.REPO, require('./handlers/repo')

  # Cache busting work-around
  app.get config.API_PATHS.BUSTIT + "/:trash/{*splat}", require('./handlers/bustit')

  # Health check endpoint
  app.get config.API_PATHS.HEALTH + '/{*splat}', require('./handlers/health')

  # Browse repository contents
  app.get config.API_PATHS.REPO + '/:repo', require('./handlers/browse-repo')

  # Get file contents
  app.get config.API_PATHS.REPO + '/:repo/file/{*splat}', require('./handlers/read-repo-file')

  # Git operations
  if config.FEATURES.GIT_OPERATIONS
    app.post config.API_PATHS.REPO + '/:repo/git/:command', require('./handlers/git')

  # Context update endpoint
  if config.FEATURES.CONTEXT_UPDATES
    app.post config.API_PATHS.CONTEXT + '/update', require('./handlers/context-update')

  # Instance coordination
  if config.FEATURES.INSTANCE_TRACKING
    app.get config.API_PATHS.INSTANCES, require('./handlers/instances')

    app.post config.API_PATHS.INSTANCES + '/register', require('./handlers/register-instance')

  # Admin interface
  app.get config.API_PATHS.ADMIN, require('./handlers/admin')

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
