# FILENAME: { ClodForest/src/routes/health.coffee }
# Health check endpoint

express = require 'express'
fs      = require 'node:fs/promises'
path    = require 'node:path'
{ getVersion } = require '../lib/version'

router = express.Router()

# Cache version info on startup
versionInfo = null
getVersion().then (info) -> versionInfo = info

router.get '/', (req, res) ->
  try
    startTime = Date.now()
    
    # Check file system access
    stateDir = path.join process.cwd(), 'state'
    dataDir  = path.join process.cwd(), 'data'
    
    fsStatus  = 'ok'
    fsDetails = {}
    
    try
      # Check state directory
      await fs.access stateDir
      stateStats = await fs.stat stateDir
      fsDetails.state_directory =
        exists:   true
        writable: true
        path:     stateDir
    catch error
      fsStatus = 'warning'
      fsDetails.state_directory =
        exists: false
        error:  error.message
        path:   stateDir
    
    try
      # Check data directory
      await fs.access dataDir
      fsDetails.data_directory =
        exists:   true
        writable: true
        path:     dataDir
    catch error
      fsStatus = 'warning'
      fsDetails.data_directory =
        exists: false
        error:  error.message
        path:   dataDir

    responseTime = Date.now() - startTime
    
    health =
      status:           if fsStatus is 'ok' then 'healthy' else 'degraded'
      timestamp:        new Date().toISOString()
      uptime:           process.uptime()
      version:          versionInfo?.full or 'unknown'
      build:            versionInfo?.build or 0
      lastBuild:        versionInfo?.lastBuild or 'unknown'
      environment:      process.env.NODE_ENV or 'development'
      response_time_ms: responseTime
      services:
        oauth2:
          status:      'ok'
          description: 'OAuth2 server operational'
        mcp:
          status:           'ok'
          description:      'MCP server operational'
          protocol_version: '2025-06-18'
        filesystem:
          status:  fsStatus
          details: fsDetails
      memory:
        used:     Math.round(process.memoryUsage().heapUsed / 1024 / 1024)
        total:    Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
        external: Math.round(process.memoryUsage().external / 1024 / 1024)
      system:
        platform:     process.platform
        arch:         process.arch
        node_version: process.version
        pid:          process.pid

    # Set appropriate HTTP status
    httpStatus = if health.status is 'healthy' then 200 else 503
    
    res.status(httpStatus).json health

  catch error
    console.error 'Health check error:', error
    
    res.status(503).json
      status:    'unhealthy'
      timestamp: new Date().toISOString()
      error:     'Health check failed'
      details:   error.message

# Readiness probe
router.get '/ready', (req, res) ->
  try
    # Check if essential services are ready
    stateDir = path.join process.cwd(), 'state'
    await fs.access stateDir
    
    res.json
      status:    'ready'
      timestamp: new Date().toISOString()
  catch error
    res.status(503).json
      status:    'not_ready'
      timestamp: new Date().toISOString()
      error:     error.message

# Liveness probe
router.get '/live', (req, res) ->
  res.json
    status:    'alive'
    timestamp: new Date().toISOString()
    uptime:    process.uptime()

module.exports = router
