# FILENAME: { ClodForest/src/app.coffee }
# Main Express application

express    = require 'express'
cors       = require 'cors'
path       = require 'node:path'
fs         = require 'node:fs/promises'

wellKnownRoutes = require './routes/wellknown'
healthRoutes    = require './routes/health'
oauthRoutes     = require './oauth/router'
mcpHandler      = require './mcp/server'
authMiddleware  = require './middleware/auth'
securityMiddleware = require './middleware/security'
{ logger, requestLogger } = require './lib/logger'

PORT = process.env.PORT or 8080

module.exports.app =
  app = express()

# Security middleware
app.use securityMiddleware

# CORS configuration
app.use cors
  origin:      process.env.CORS_ORIGIN or '*'
  credentials: true

# Body parsing middleware
app.use express.json limit: '10mb'
app.use express.urlencoded extended: true, limit: '10mb'

# Request logging middleware
app.use requestLogger

# Well-known endpoints (RFC 5785)
app.use '/.well-known', wellKnownRoutes

# Health check endpoint
app.use '/api/health', healthRoutes

# OAuth2 endpoints (oidc-provider needs to be at root for well-known endpoints)
app.use oauthRoutes

# MCP endpoint (OAuth2 protected)
app.use '/api/mcp', authMiddleware, mcpHandler

# Error handling middleware
app.use (err, req, res, next) ->
  logger.error 'HTTP Error', { error: err.message, stack: err.stack, status: err.status }
  res.status(err.status or 500).json
    error:   'Internal Server Error'
    message: if process.env.NODE_ENV is 'development' then err.message else 'Something went wrong'

# 404 handler
app.use (req, res) ->
  res.status(404).json
    error:   'Not Found'
    message: 'The requested resource was not found'

# Start server
app.listen PORT, ->
  startupMessage = """
    ClodForest MCP Server running on port #{PORT}
    Environment:         #{process.env.NODE_ENV or 'development'}
    OAuth2 endpoints:    /oauth/*
    MCP endpoint:        /api/mcp
    Well-known endpoints: /.well-known/*
  """
  
  console.log startupMessage
  logger.info 'Server started', {
    port: PORT
    environment: process.env.NODE_ENV or 'development'
    pid: process.pid
  }
