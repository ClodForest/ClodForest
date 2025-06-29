# FILENAME: { ClodForest/src/echo/lib/router.coffee }
# Simple HTTP router for JSON-RPC Echo Server

utils   = require './utils'
jsonrpc = require './jsonrpc'
config  = require './config'

# Health check handler
handleHealth = (req, res) ->
  healthData =
    status:    'ok'
    service:   config.SERVICE_NAME
    version:   config.VERSION
    timestamp: new Date().toISOString()
    uptime:    process.uptime()
    memory:    process.memoryUsage()
    
  utils.sendJsonResponse res, 200, healthData

# Welcome page handler
handleWelcome = (req, res) ->
  html = utils.generateWelcomePage()
  utils.sendHtmlResponse res, 200, html

# JSON-RPC handler
handleJsonRpc = (req, res) ->
  utils.parseRequestBody req, (error, body) ->
    if error
      return utils.sendJsonResponse res, 413, 
        jsonrpc: config.JSONRPC_VERSION
        error:
          code:    -32700
          message: error.message
        id: null
    
    jsonrpc.processJsonRpc body, (response) ->
      if response
        utils.sendJsonResponse res, 200, response
      else
        # Notification request - no response needed
        res.writeHead 204
        res.end()

# 404 handler
handle404 = (req, res) ->
  errorData =
    error:     'Not Found'
    path:      req.url
    method:    req.method
    timestamp: new Date().toISOString()
    
  utils.sendJsonResponse res, 404, errorData

# Main request handler
handle = (req, res) ->
  utils.logRequest req
  
  # Handle OPTIONS preflight
  if req.method is 'OPTIONS'
    return utils.handleOptions req, res
  
  # Parse URL
  urlInfo = utils.parseUrl req
  
  # Route requests
  switch urlInfo.pathname
    when '/'
      if req.method is 'GET'
        handleWelcome req, res
      else
        handle404 req, res
    
    when '/health'
      if req.method is 'GET'
        handleHealth req, res
      else
        handle404 req, res
    
    when '/rpc'
      if req.method is 'POST'
        handleJsonRpc req, res
      else
        handle404 req, res
    
    else
      handle404 req, res

module.exports = {
  handle
  handleHealth
  handleWelcome
  handleJsonRpc
  handle404
}
