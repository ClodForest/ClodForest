# ClodForest Logging Module
# File-based logging with rotation and real client IP detection

fs     = require 'fs'
path   = require 'path'
config = require './config'

# Log levels
LOG_LEVELS =
  error: 0
  warn:  1
  info:  2
  debug: 3

# Current log level
currentLogLevel = LOG_LEVELS[config.LOG_LEVEL] ? LOG_LEVELS.info

# Log file streams
logStreams = {}

# Initialize logging system
initializeLogging = ->
  # Ensure log directory exists
  try
    fs.mkdirSync config.LOG_DIR, recursive: true
  catch error
    console.error "Failed to create log directory #{config.LOG_DIR}:", error.message
    return false
  
  # Initialize log streams
  logFiles = ['access', 'error', 'debug']
  
  for logType in logFiles
    logPath = path.join(config.LOG_DIR, "#{logType}.log")
    try
      logStreams[logType] = fs.createWriteStream(logPath, flags: 'a')
      logStreams[logType].on 'error', (error) ->
        console.error "Log stream error for #{logType}:", error.message
    catch error
      console.error "Failed to create log stream for #{logType}:", error.message
      return false
  
  console.log "Logging initialized - files in #{config.LOG_DIR}/"
  true

# Extract real client IP from request
getRealClientIP = (req) ->
  return 'unknown' unless config.TRUST_PROXY
  
  # Check various headers in priority order
  headers = [
    'x-forwarded-for'
    'x-real-ip'
    'cf-connecting-ip'
    'x-client-ip'
    'x-forwarded'
    'forwarded-for'
    'forwarded'
  ]
  
  for header in headers
    value = req.get(header)
    if value
      # X-Forwarded-For can be comma-separated list, take first (real client)
      if header is 'x-forwarded-for'
        ips = value.split(',').map((ip) -> ip.trim())
        return ips[0] if ips[0] and ips[0] isnt 'unknown'
      else
        return value.trim() if value.trim() isnt 'unknown'
  
  # Fallback to connection info
  req.ip or req.connection?.remoteAddress or req.socket?.remoteAddress or 'unknown'

# Format log entry
formatLogEntry = (level, message, metadata = {}) ->
  entry =
    timestamp: new Date().toISOString()
    level: level
    message: message
  
  # Add metadata if provided
  Object.assign(entry, metadata) if Object.keys(metadata).length > 0
  
  JSON.stringify(entry) + '\n'

# Write to log file
writeToLog = (logType, level, message, metadata = {}) ->
  return unless logStreams[logType]
  return if LOG_LEVELS[level] > currentLogLevel
  
  entry = formatLogEntry(level, message, metadata)
  logStreams[logType].write(entry)
  
  # Also write errors to console in development
  if level is 'error' and config.isDevelopment
    console.error message

# Log functions
log =
  error: (message, metadata) ->
    writeToLog('error', 'error', message, metadata)
    console.error "[ERROR] #{message}" if config.isDevelopment
  
  warn: (message, metadata) ->
    writeToLog('error', 'warn', message, metadata)
    console.warn "[WARN] #{message}" if config.debugMode
  
  info: (message, metadata) ->
    writeToLog('debug', 'info', message, metadata)
    console.log "[INFO] #{message}" if config.debugMode
  
  debug: (message, metadata) ->
    writeToLog('debug', 'debug', message, metadata)
    console.log "[DEBUG] #{message}" if config.debugMode

# Access log function
logAccess = (req, res, responseTime) ->
  return unless logStreams.access
  
  clientIP = getRealClientIP(req)
  userAgent = req.get('User-Agent') or 'unknown'
  referer = req.get('Referer') or '-'
  
  # Build query string
  queryString = ''
  if Object.keys(req.query).length > 0
    queryString = "?#{new URLSearchParams(req.query).toString()}"
  
  # Access log entry
  accessEntry =
    timestamp: new Date().toISOString()
    client_ip: clientIP
    method: req.method
    url: req.originalUrl or req.url
    path: req.path
    query: queryString
    status: res.statusCode
    response_time_ms: responseTime
    user_agent: userAgent
    referer: referer
    content_length: res.get('Content-Length') or 0
  
  # Add request ID if available
  if req.get('X-Request-ID')
    accessEntry.request_id = req.get('X-Request-ID')
  
  # Add ClaudeLink instance if available
  if req.get('X-ClaudeLink-Instance')
    accessEntry.claude_instance = req.get('X-ClaudeLink-Instance')
  
  logStreams.access.write(JSON.stringify(accessEntry) + '\n')

# Request logging middleware
requestLogger = (req, res, next) ->
  startTime = Date.now()
  clientIP = getRealClientIP(req)
  
  # Store original end method
  originalEnd = res.end
  
  # Override end method to log when response is sent
  res.end = (chunk, encoding) ->
    responseTime = Date.now() - startTime
    logAccess(req, res, responseTime)
    
    # Console log for immediate feedback
    timestamp = new Date().toISOString()
    queryString = if Object.keys(req.query).length > 0 then "?#{new URLSearchParams(req.query).toString()}" else ''
    
    if config.debugMode
      console.log "[#{timestamp}] #{clientIP} #{req.method} #{req.path}#{queryString} #{res.statusCode} #{responseTime}ms"
    else
      console.log "[#{timestamp}] #{req.method} #{req.path} #{res.statusCode}"
    
    # Call original end
    originalEnd.call(this, chunk, encoding)
  
  next()

# Graceful shutdown
shutdown = ->
  console.log 'Closing log streams...'
  for logType, stream of logStreams
    stream?.end()
  logStreams = {}

# Log rotation (simple daily rotation)
rotateLogsDaily = ->
  return unless config.LOG_ROTATION is 'daily'
  
  yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  dateStr = yesterday.toISOString().split('T')[0]  # YYYY-MM-DD
  
  for logType of logStreams
    oldPath = path.join(config.LOG_DIR, "#{logType}.log")
    newPath = path.join(config.LOG_DIR, "#{logType}.#{dateStr}.log")
    
    try
      if fs.existsSync(oldPath)
        fs.renameSync(oldPath, newPath)
        console.log "Rotated #{logType}.log to #{logType}.#{dateStr}.log"
    catch error
      log.error "Failed to rotate #{logType}.log", error: error.message

# Set up daily rotation if enabled
if config.LOG_ROTATION is 'daily'
  # Rotate at midnight
  now = new Date()
  msUntilMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 0) - now
  
  setTimeout ->
    rotateLogsDaily()
    # Then rotate daily
    setInterval(rotateLogsDaily, 24 * 60 * 60 * 1000)
  , msUntilMidnight

module.exports = {
  initializeLogging
  getRealClientIP
  requestLogger
  log
  logAccess
  shutdown
}
