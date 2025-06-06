express    = require 'express'
cors       = require 'cors'

routing    = require './lib/routing'
middleware = require './lib/middleware'
config     = require './lib/config'


URL_PREFIX = "https://#{config.VAULT_SERVER}"


module.exports.app =
  app = express()

middleware.setup(app)
routing   .setup(app)


module.exports.server =
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


shutdownGracefully = ->
  console.log 'Shutting down gracefully...'

  server.close ->
    console.log 'Server closed'
    process.exit 0

process.on 'SIGTERM', shutdownGracefully
process.on 'SIGINT',  shutdownGracefully
