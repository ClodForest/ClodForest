# ClodForest Coordinator Service
# Modular CoffeeScript implementation

express = require 'express'
cors    = require 'cors'

# Import our modules
routing    = require './lib/routing'
middleware = require './lib/middleware'
config     = require './lib/config'

# Create Express app
app = express()

# Apply middleware stack
middleware.setup(app)

# Apply routing
routing.setup(app)

# Start server
server = app.listen config.PORT, ->
  console.log """
  🔗 ClodForest Coordinator Started

  Port: #{config.PORT}
  Environment: #{config.NODE_ENV or 'development'}
  Repository Path: #{config.REPO_PATH}
  Vault Server: #{config.VAULT_SERVER}

  API Endpoints:
    Health: http://localhost:#{config.PORT}/api/health/
    Time: http://localhost:#{config.PORT}/api/time/
    Repositories: http://localhost:#{config.PORT}/api/repo
    Admin: http://localhost:#{config.PORT}/admin

  Response Format: YAML (default) or JSON (with Accept: application/json header)
  """

# Graceful shutdown handlers
shutdownGracefully = ->
  console.log 'Shutting down gracefully...'
  server.close ->
    console.log 'Server closed'
    process.exit 0

process.on 'SIGTERM', shutdownGracefully
process.on 'SIGINT', shutdownGracefully

module.exports = { app, server }