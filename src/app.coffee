# FILENAME: { ClodForest/src/app.coffee }
# Main Express application

path               = require 'node:path'
fs                 = require 'node:fs/promises'

express            = require 'express'
cors               = require 'cors'

wellKnownRoutes    = require './routes/wellknown'
healthRoutes       = require './routes/health'
oauthRoutes        = require './oauth/router'
mcpHandler         = require './mcp/server'
{ createSseRouter } = require './mcp/sse-server'
authMiddleware     = require './middleware/auth'
securityMiddleware = require './middleware/security'

{ logger, requestLogger } = require './lib/logger'

PORT = process.env.PORT or 8080

module.exports.app =
  app = express()

app.use securityMiddleware

app.use cors
  origin:      process.env.CORS_ORIGIN or '*'
  credentials: true

app.use express.json limit: '10mb'
app.use express.urlencoded extended: true, limit: '10mb'

app.use requestLogger

# Smart authentication middleware that protects only specific paths
app.use authMiddleware

app.use oauthRoutes

app.get '/.well-known/oauth-authorization-server', (req, res) ->
  res.redirect '/oauth/.well-known/oauth-authorization-server'

app.use '/.well-known', wellKnownRoutes

app.use '/api/health',  healthRoutes
# SSE-based MCP server with modern protocol support
sseRouter = createSseRouter()
app.use '/api/mcp-sse', sseRouter
app.use '/api/mcp',     mcpHandler

# Root path handler for service discovery
app.get '/', (req, res) ->
  # Handle AWS ALB/CloudFront forwarded headers
  protocol = req.get('X-Forwarded-Proto') or req.protocol or 'http'
  host = req.get('X-Forwarded-Host') or req.get('host') or "localhost:#{process.env.PORT or 8080}"
  baseUrl = "#{protocol}://#{host}"
  
  res.json
    name: 'ClodForest MCP Server'
    version: '1.0.0'
    description: 'OAuth2-secured MCP server for LLM state management'
    endpoints:
      mcp: "#{baseUrl}/api/mcp"
      mcpSse: "#{baseUrl}/api/mcp-sse/sse"
      health: "#{baseUrl}/api/health"
      oauth: "#{baseUrl}/oauth"
      wellKnown: "#{baseUrl}/.well-known"
    transport:
      legacy: "#{baseUrl}/api/mcp"
      sse: "#{baseUrl}/api/mcp-sse/sse"

# Debug route to list all registered routes
app.get '/debug/routes', (req, res) ->
  routes = []
  
  try
    # Simple route extraction
    if app._router?.stack
      app._router.stack.forEach (layer) ->
        try
          if layer?.route
            routes.push
              path: layer.route.path
              methods: Object.keys(layer.route.methods || {}).join(', ').toUpperCase()
          else if layer?.name
            routes.push
              type: 'middleware'
              name: layer.name
              regexp: layer.regexp?.source
        catch layerError
          routes.push
            type: 'error'
            error: layerError.message
  catch error
    logger.error 'Debug route error', { error: error.message }
  
  res.json
    totalRoutes: routes.length
    routes: routes

app.use (err, req, res, next) ->
  logger.error 'HTTP Error', { 
    error: err?.message or 'Unknown error'
    stack: err?.stack or 'No stack trace'
    status: err?.status
    type: typeof err
  }
  res.status(err?.status or 500).json
    error:   'Internal Server Error'
    message: if process.env.NODE_ENV is 'development' then (err?.message or 'Unknown error') else 'Something went wrong'

app.use (req, res) ->
  res.status(404).json
    error:   'Not Found'
    message: 'The requested resource was not found'

app.listen PORT, ->
  startupMessage = """
    ClodForest MCP Server running on port #{PORT}
    Environment:         #{process.env.NODE_ENV or 'development'}
    OAuth2 endpoints:    /oauth/*
    MCP endpoint:        /api/mcp
    SSE MCP endpoint:    /api/mcp/sse
    Well-known endpoints: /.well-known/*
  """

  console.log startupMessage
  logger.info 'Server started', {
    port: PORT
    environment: process.env.NODE_ENV or 'development'
    pid: process.pid
  }
