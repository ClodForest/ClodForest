express    = require 'express'
cors       = require 'cors'

routing    = require './lib/routing'
middleware = require './lib/middleware'
config     = require './lib/config'


URL_PREFIX = "https://#{config.VAULT_SERVER}"


# Create and configure app
app = express()

middleware.setup(app)
routing   .setup(app)


# Server instance (only created when startServer is called)
server = null


# Function to start the server
startServer = (callback) ->
  server = app.listen config.PORT, ->
    console.log """
      🔗 ClodForest Coordinator Started

      Port:            #{config.PORT}
      Environment:     #{config.NODE_ENV or 'development'}
      Repository Path: #{config.REPO_PATH}
      Vault Server:    #{config.VAULT_SERVER}

      API Endpoints:
        Health:        #{URL_PREFIX}/api/health/
        Time:          #{URL_PREFIX}/api/time/
        Repositories:  #{URL_PREFIX}/api/repo
        Admin:         #{URL_PREFIX}/admin
    """
    
    callback?()


# Graceful shutdown handler
shutdownGracefully = ->
  console.log 'Shutting down gracefully...'
  
  if server
    server.close ->
      console.log 'Server closed'
      process.exit 0
  else
    process.exit 0


# Export app and server control functions
module.exports = {
  app
  server: -> server  # Getter function for server instance
  startServer
  shutdownGracefully
}


# Only start server if this file is run directly
if require.main is module
  startServer()
  
  process.on 'SIGTERM', shutdownGracefully
  process.on 'SIGINT',  shutdownGracefully
