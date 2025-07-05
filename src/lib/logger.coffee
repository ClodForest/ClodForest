# FILENAME: { ClodForest/src/lib/logger.coffee }
# Logging utility for ClodForest

fs   = require 'node:fs/promises'
path = require 'node:path'

# Ensure logs directory exists
LOGS_DIR = path.join process.cwd(), 'logs'

ensureLogsDir = ->
  try
    await fs.mkdir LOGS_DIR, recursive: true
  catch error
    console.error "Failed to create logs directory:", error

# Log levels
LOG_LEVELS =
  ERROR: 0
  WARN:  1
  INFO:  2
  DEBUG: 3

# Current log level (can be set via environment)
CURRENT_LEVEL = LOG_LEVELS[process.env.LOG_LEVEL?.toUpperCase()] ? LOG_LEVELS.INFO

# Format timestamp
formatTimestamp = ->
  new Date().toISOString()

# Write to log file
writeToFile = (filename, level, message, data = null) ->
  try
    await ensureLogsDir()
    
    logEntry =
      timestamp: formatTimestamp()
      level:     level
      message:   message
      pid:       process.pid
    
    if data
      logEntry.data = data
    
    logLine = JSON.stringify(logEntry) + '\n'
    filePath = path.join LOGS_DIR, filename
    
    await fs.appendFile filePath, logLine
  catch error
    console.error "Failed to write to log file #{filename}:", error

# Console logging with file backup
logToConsoleAndFile = (level, filename, message, data = null) ->
  # Always log to console for immediate feedback
  if data
    console.log "#{formatTimestamp()} [#{level}] #{message}", data
  else
    console.log "#{formatTimestamp()} [#{level}] #{message}"
  
  # Also write to file if level is appropriate
  if LOG_LEVELS[level] <= CURRENT_LEVEL
    writeToFile filename, level, message, data

# Exported logging functions
module.exports.logger =
  logger =
    # General application logs
    info: (message, data = null) ->
      logToConsoleAndFile 'INFO', 'app.log', message, data
    
    warn: (message, data = null) ->
      logToConsoleAndFile 'WARN', 'app.log', message, data
    
    error: (message, data = null) ->
      logToConsoleAndFile 'ERROR', 'error.log', message, data
    
    debug: (message, data = null) ->
      logToConsoleAndFile 'DEBUG', 'debug.log', message, data
    
    # HTTP access logs
    access: (req, res, responseTime = null) ->
      logData =
        method:     req.method
        url:        req.url
        ip:         req.ip or req.connection?.remoteAddress
        userAgent:  req.get('User-Agent')
        status:     res.statusCode
        
      if responseTime
        logData.responseTime = "#{responseTime}ms"
      
      writeToFile 'access.log', 'INFO', 'HTTP Request', logData
    
    # MCP protocol logs
    mcp: (message, data = null) ->
      writeToFile 'mcp.log', 'INFO', message, data
    
    # OAuth2 logs
    oauth: (message, data = null) ->
      writeToFile 'oauth.log', 'INFO', message, data

# Middleware for HTTP request logging
module.exports.requestLogger =
  requestLogger = (req, res, next) ->
    startTime = Date.now()
    
    # Log the request
    logger.access req, res
    
    # Override res.end to capture response time
    originalEnd = res.end
    res.end = (chunk, encoding) ->
      responseTime = Date.now() - startTime
      logger.access req, res, responseTime
      originalEnd.call res, chunk, encoding
    
    next()
