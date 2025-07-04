# ClodForest Middleware Module
# Request processing, CORS, logging, security, and response formatting

express = require 'express'
cors    = require 'cors'
yaml    = require 'js-yaml'
config  = require './config'
logger  = require './logger'

# CORS configuration
corsOptions =
  origin: config.CORS_ORIGINS
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
  allowedHeaders: [
    'Content-Type'
    'Authorization'
    'X-ClaudeLink-Instance'
    'X-ClaudeLink-Token'
    'Accept'
    'Accept-Language'
    'Content-Language'
  ]
  credentials: true
  maxAge: 86400  # 24 hours

# Request logging middleware (now uses enhanced logger)
requestLogger = logger.requestLogger

# Security middleware
securityMiddleware = (req, res, next) ->
  # Basic path traversal protection
  if req.path.includes('..')
    return res.status(400).json error: 'Invalid path'
  next()

# Response format middleware - JSON first, YAML fallback
formatResponse = (req, res, data) ->
  acceptHeader = req.get('Accept') or ''
  preferJson = not acceptHeader.includes('application/yaml')

  if preferJson
    res.set 'Content-Type', config.RESPONSE_FORMATS.JSON_TYPE
    res.send JSON.stringify(data, null, 2)
  else
    res.set 'Content-Type', config.RESPONSE_FORMATS.YAML_TYPE
    res.send yaml.dump(data, indent: 2)

# Add timestamp to all API responses
timestampMiddleware = (req, res, next) ->
  # Store original json method
  originalJson = res.json
  
  # Override json method to add timestamp
  res.json = (data) ->
    if typeof data is 'object' and data isnt null
      data.timestamp = new Date().toISOString() unless data.timestamp
    originalJson.call(this, data)
  
  next()

# Setup function to apply all middleware to app
setup = (app) ->
  # Basic Express middleware
  app.use express.json()
  
  # CORS
  app.use cors(corsOptions)
  
  # Custom middleware stack
  app.use requestLogger
  app.use securityMiddleware
  app.use timestampMiddleware
  
  # Attach formatResponse helper to app for route handlers
  app.formatResponse = formatResponse

module.exports = {
  setup
  formatResponse
  requestLogger
  securityMiddleware
  timestampMiddleware
}
