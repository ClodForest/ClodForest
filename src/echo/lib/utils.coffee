# FILENAME: { ClodForest/src/echo/lib/utils.coffee }
# HTTP utilities for JSON-RPC Echo Server

url    = require 'url'
config = require './config'

# CORS headers setup
setCorsHeaders = (res) ->
  if config.FEATURES.CORS_ENABLED
    res.setHeader 'Access-Control-Allow-Origin',  '*'
    res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, OPTIONS'
    res.setHeader 'Access-Control-Allow-Headers', 'Content-Type, Accept'
    res.setHeader 'Access-Control-Max-Age',       '86400'

# Request logging
logRequest = (req) ->
  timestamp = new Date().toISOString()
  clientIP  = req.socket.remoteAddress or 'unknown'
  
  console.log "[#{timestamp}] #{clientIP} #{req.method} #{req.url}"

# Parse request body
parseRequestBody = (req, callback) ->
  body = ''
  
  req.on 'data', (chunk) ->
    body += chunk.toString()
    
    # Prevent oversized requests
    if body.length > config.MAX_REQUEST_SIZE
      callback new Error('Request too large'), null
      return
  
  req.on 'end', ->
    callback null, body

# Send JSON response
sendJsonResponse = (res, statusCode, data) ->
  setCorsHeaders res
  res.writeHead statusCode, 'Content-Type': 'application/json'
  res.end JSON.stringify(data, null, 2)

# Send HTML response
sendHtmlResponse = (res, statusCode, html) ->
  setCorsHeaders res
  res.writeHead statusCode, 'Content-Type': 'text/html'
  res.end html

# Send plain text response
sendTextResponse = (res, statusCode, text) ->
  setCorsHeaders res
  res.writeHead statusCode, 'Content-Type': 'text/plain'
  res.end text

# Handle OPTIONS preflight
handleOptions = (req, res) ->
  setCorsHeaders res
  res.writeHead 204
  res.end()

# Parse URL and query parameters
parseUrl = (req) ->
  parsed = url.parse req.url, true
  
  pathname: parsed.pathname
  query:    parsed.query

# Generate welcome page HTML
generateWelcomePage = ->
  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>#{config.SERVICE_NAME}</title>
    <style>
      body { 
        font-family: monospace; 
        margin: 40px; 
        background: #1a1a1a; 
        color: #00ff00; 
        line-height: 1.6;
      }
      .header { 
        color: #00ffff; 
        font-size: 24px; 
        margin-bottom: 20px; 
      }
      .status { 
        color: #00ff00; 
        margin: 5px 0;
      }
      .endpoint { 
        color: #ffff00; 
        margin: 5px 0; 
      }
      .example { 
        background: #333; 
        padding: 15px; 
        margin: 10px 0; 
        border-left: 3px solid #00ffff;
        overflow-x: auto;
      }
      .method { 
        color: #ffffff; 
        margin: 3px 0; 
      }
      pre { 
        margin: 0; 
        white-space: pre-wrap;
      }
    </style>
  </head>
  <body>
    <div class="header">🔊 #{config.SERVICE_NAME}</div>
    <div class="status">Status: Running</div>
    <div class="status">Version: #{config.VERSION}</div>
    <div class="status">JSON-RPC: #{config.JSONRPC_VERSION}</div>
    <br>
    
    <div>Endpoints:</div>
    <div class="endpoint">• POST /rpc - JSON-RPC endpoint</div>
    <div class="endpoint">• GET /health - Health check</div>
    <div class="endpoint">• GET / - This page</div>
    <br>
    
    <div>Available Methods:</div>
    <div class="method">• #{config.ECHO_METHODS.SIMPLE} - Simple parameter echo</div>
    <div class="method">• #{config.ECHO_METHODS.ENHANCED} - Echo with metadata</div>
    <div class="method">• #{config.ECHO_METHODS.DELAY} - Delayed echo (params.delay_ms)</div>
    <div class="method">• #{config.ECHO_METHODS.ERROR} - Error response test</div>
    <br>
    
    <div>Example Request:</div>
    <div class="example">
      <pre>{
  "jsonrpc": "2.0",
  "method": "echo.simple",
  "params": {"message": "Hello, World!"},
  "id": 1
}</pre>
    </div>
    
    <div>Example Response:</div>
    <div class="example">
      <pre>{
  "jsonrpc": "2.0",
  "result": {"message": "Hello, World!"},
  "id": 1
}</pre>
    </div>
  </body>
  </html>
  """

module.exports = {
  setCorsHeaders
  logRequest
  parseRequestBody
  sendJsonResponse
  sendHtmlResponse
  sendTextResponse
  handleOptions
  parseUrl
  generateWelcomePage
}
