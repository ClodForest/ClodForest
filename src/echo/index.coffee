#!/usr/bin/env coffee
# FILENAME: { ClodForest/src/echo/index.coffee }

http   = require 'http'
config = require './lib/config'
router = require './lib/router'


server = http.createServer (req, res) ->
  router.handle req, res

server.listen config.PORT, ->
  console.log """
    🔊 JSON-RPC Echo Server Started

    Port:        #{config.PORT}
    Environment: #{config.NODE_ENV or 'development'}
    Endpoints:
      RPC:       http://localhost:#{config.PORT}/rpc
      Health:    http://localhost:#{config.PORT}/health
      Welcome:   http://localhost:#{config.PORT}/
  """

module.exports.server = server


shutdownGracefully = ->
  console.log 'Shutting down gracefully...'
  
  server.close ->
    console.log 'Echo server closed'
    process.exit 0

process.on 'SIGTERM', shutdownGracefully
process.on 'SIGINT',  shutdownGracefully


# Start server if this file is run directly
if require.main is module
  module.exports.server
