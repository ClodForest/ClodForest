# ClaudeLink Coordinator Service
# CoffeeScript implementation with YAML-first API responses

express = require 'express'
cors    = require 'cors'
fs      = require 'fs'
path    = require 'path'
{exec}  = require 'child_process'
yaml    = require 'js-yaml'

# Configuration
app          = express()
PORT         = process.env.PORT         or 8080
VAULT_SERVER = process.env.VAULT_SERVER or 'claudelink-vault'
REPO_PATH    = process.env.REPO_PATH    or '/var/repositories'

# Middleware setup
app.use express.json()

# Enhanced CORS configuration
corsOptions =
  origin: [
    'https://claude.ai'
    'https://*.claude.ai'
    'https://chat.openai.com'
    'https://*.openai.com'
    'http://localhost:3000'
    'http://localhost:8080'
    'http://127.0.0.1:8080'
  ]

  methods: [
    'GET'
    'POST'
    'PUT'
    'DELETE'
    'OPTIONS'
  ]

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
  maxAge:      86400  # 24 hours

app.use cors(corsOptions)

# Request logging middleware
app.use (req, res, next) ->
  timestamp = new Date().toISOString()
  clientIP = req.ip || req.connection.remoteAddress || req.socket.remoteAddress || 'unknown'
  queryString = if Object.keys(req.query).length > 0 then "?#{new URLSearchParams(req.query).toString()}" else ''

  if process.env.LOG_LEVEL is 'debug'
    console.log "[#{timestamp}] #{clientIP} #{req.method} #{req.path}#{queryString}"
  else
    console.log "[#{timestamp}] #{req.method} #{req.path}"
  next()

# Security middleware
app.use (req, res, next) ->
  # Basic path traversal protection
  if req.path.includes('..')
    return res.status(400).json error: 'Invalid path'

  next()

# Response format middleware - YAML first, JSON fallback
formatResponse = (req, res, data) ->
  acceptHeader = req.get('Accept') or ''
  preferJson   = not acceptHeader.includes('application/yaml')
  # preferJson   = acceptHeader.includes('application/json') and
  #                not acceptHeader.includes('application/yaml')

  if preferJson
    res.set 'Content-Type', 'application/json'
    res.send JSON.stringify(data, null, 2)
  else
    res.set 'Content-Type', 'application/yaml'
    res.send yaml.dump(data, indent: 2)

# Welcome page - serves as API documentation and status
app.get '/', (req, res) ->
  welcomeData =
    service:     'ClaudeLink Coordinator'
    version:     '1.0.0'
    status:      'operational'
    description: 'Coordination service for distributed Claude instances'
    timestamp:   new Date().toISOString()

    endpoints:
      health:     '/api/health'
      time:       '/api/time'
      repository: '/api/repository'
      context:    '/api/context/update'
      instances:  '/api/instances'
      admin:      '/admin'

    features: [
      'Time synchronization service'
      'Repository access and management'
      'Context update coordination'
      'Instance registration and discovery'
      'Administrative interface'
    ]

    documentation: 'https://claudelink.thatsnice.org/docs'
    support:       'rdeforest@thatsnice.org'

  if req.get('Accept')?.includes('text/html')
    # Serve HTML welcome page
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>ClaudeLink Coordinator</title>
      <style>
        body { font-family: monospace; margin: 40px; background: #1a1a1a; color: #00ff00; }
        .header { color: #00ffff; font-size: 24px; margin-bottom: 20px; }
        .status { color: #00ff00; }
        .endpoint { color: #ffff00; margin: 5px 0; }
        .feature { color: #ffffff; margin: 3px 0; }
        a { color: #00ffff; }
      </style>
    </head>
    <body>
      <div class="header">🔗 ClaudeLink Coordinator</div>
      <div class="status">Status: #{welcomeData.status}</div>
      <div class="status">Version: #{welcomeData.version}</div>
      <br>
      <div>API Endpoints:</div>
      <div class="endpoint">• <a href="/api/health">/api/health</a> - Service health check</div>
      <div class="endpoint">• <a href="/api/time">/api/time</a> - Time synchronization</div>
      <div class="endpoint">• <a href="/api/repository">/api/repository</a> - Repository listing</div>
      <div class="endpoint">• <a href="/admin">/admin</a> - Administrative interface</div>
      <br>
      <div>Features:</div>
      #{welcomeData.features.map((f) -> "<div class=\"feature\">• #{f}</div>").join('')}
      <br>
      <div>Format: Add <code>Accept: application/json</code> header for JSON, defaults to YAML</div>
    </body>
    </html>
    """
    res.send html
  else
    formatResponse req, res, welcomeData

# Health check endpoint
app.get '/api/health', (req, res) ->
  uptime   = process.uptime()
  memUsage = process.memoryUsage()

  healthData =
    status:    'healthy'
    timestamp: new Date().toISOString()
    uptime:    "#{Math.floor(uptime)} seconds"

    memory:
      rss:       "#{Math.round(memUsage.rss / 1024 / 1024)} MB"
      heapUsed:  "#{Math.round(memUsage.heapUsed / 1024 / 1024)} MB"
      heapTotal: "#{Math.round(memUsage.heapTotal / 1024 / 1024)} MB"

    environment:
      nodeVersion: process.version
      platform:    process.platform
      arch:        process.arch

    services:
      vaultServer:    VAULT_SERVER
      repositoryPath: REPO_PATH

  formatResponse req, res, healthData

# Time service for instance synchronization
app.get '/api/time', (req, res) ->
  now = new Date()

  timeData =
    timestamp: now.toISOString()
    unix:      Math.floor(now.getTime() / 1000)
    timezone:  'UTC'

    formats:
      iso8601:      now.toISOString()
      rfc2822:      now.toUTCString()
      unix:         Math.floor(now.getTime() / 1000)
      milliseconds: now.getTime()

    requestor: req.get('X-ClaudeLink-Instance') or 'unknown'

  formatResponse req, res, timeData

# Repository operations
app.get '/api/repository', (req, res) ->
  try
    repositories = fs.readdirSync(REPO_PATH)
      .filter (item) ->
        itemPath = path.join(REPO_PATH, item)
        fs.statSync(itemPath).isDirectory()

    repoData =
      repositories: repositories
      count:        repositories.length
      path:         REPO_PATH
      server:       VAULT_SERVER
      timestamp:    new Date().toISOString()

    formatResponse req, res, repoData

  catch error
    formatResponse req, res,
      error:     'Repository access failed'
      message:   error.message
      timestamp: new Date().toISOString()

# Browse repository contents
app.get '/api/repository/:repo', (req, res) ->
  {repo}     = req.params
  browsePath = req.query.path or ''

  fullPath = path.join(REPO_PATH, repo, browsePath)

  try
    items = fs.readdirSync(fullPath)
      .map (item) ->
        itemPath = path.join(fullPath, item)
        stat     = fs.statSync(itemPath)

        name:     item
        type:     if stat.isDirectory() then 'directory' else 'file'
        size:     stat.size
        modified: stat.mtime.toISOString()

    browseData =
      repository: repo
      path:       browsePath
      items:      items
      count:      items.length
      timestamp:  new Date().toISOString()

    formatResponse req, res, browseData

  catch error
    formatResponse req, res,
      error:      'Browse failed'
      message:    error.message
      repository: repo
      path:       browsePath

# Get file contents
app.get '/api/repository/:repo/file/*', (req, res) ->
  {repo}   = req.params
  filePath = req.params[0]  # Everything after /file/

  fullPath = path.join(REPO_PATH, repo, filePath)

  try
    content = fs.readFileSync(fullPath, 'utf8')
    stat    = fs.statSync(fullPath)

    fileData =
      repository: repo
      file:       filePath
      content:    content
      size:       stat.size
      modified:   stat.mtime.toISOString()
      timestamp:  new Date().toISOString()

    formatResponse req, res, fileData

  catch error
    formatResponse req, res,
      error:      'File read failed'
      message:    error.message
      repository: repo
      file:       filePath

# Git operations
allowedGitCommands = ['status', 'log', 'diff', 'branch', 'pull', 'push', 'checkout']

app.post '/api/repository/:repo/git/:command', (req, res) ->
  {repo, command} = req.params
  {args = []}     = req.body

  unless command in allowedGitCommands
    return formatResponse req, res,
      error:   'Git command not allowed'
      command: command
      allowed: allowedGitCommands

  repoPath   = path.join(REPO_PATH, repo)
  gitCommand = "git -C #{repoPath} #{command} #{args.join(' ')}"

  exec gitCommand, (error, stdout, stderr) ->
    gitData =
      repository: repo
      command:    command
      args:       args
      timestamp:  new Date().toISOString()

    if error
      gitData.error  = error.message
      gitData.stderr = stderr
    else
      gitData.stdout = stdout
      gitData.stderr = stderr if stderr

    formatResponse req, res, gitData

# Context update endpoint
app.post '/api/context/update', (req, res) ->
  instanceId = req.get('X-ClaudeLink-Instance') or 'unknown'
  {requestor, requests} = req.body

  updateData =
    status:       'received'
    requestor:    requestor or instanceId
    requestCount: requests?.length or 0
    timestamp:    new Date().toISOString()
    message:      'Context update processing not yet implemented'

  # TODO: Implement actual context update processing
  formatResponse req, res, updateData

# Instance coordination
instances = new Map()

app.get '/api/instances', (req, res) ->
  instanceData =
    instances: Array.from(instances.values())
    count:     instances.size
    timestamp: new Date().toISOString()

  formatResponse req, res, instanceData

# Admin interface (basic HTML for now)
app.get '/admin', (req, res) ->
  # In development mode, bypass authentication
  isDev = process.env.NODE_ENV isnt 'production'

  html = """
  <!DOCTYPE html>
  <html>
  <head>
    <title>ClaudeLink Admin</title>
    <style>
      body { font-family: monospace; margin: 20px; background: #1a1a1a; color: #00ff00; }
      .header { color: #00ffff; font-size: 20px; margin-bottom: 20px; }
      .section { margin: 20px 0; padding: 15px; border: 1px solid #333; }
      .status-ok { color: #00ff00; }
      .status-warn { color: #ffff00; }
      button { background: #333; color: #00ff00; border: 1px solid #666; padding: 5px 10px; margin: 5px; }
      input { background: #222; color: #00ff00; border: 1px solid #666; padding: 5px; }
      a { color: #00ffff; }
    </style>
  </head>
  <body>
    <div class="header">🔗 ClaudeLink Admin Dashboard</div>

    #{if isDev then '<div class="status-warn">⚠️ Development Mode - Authentication Bypassed</div>' else ''}

    <div class="section">
      <h3>Service Status</h3>
      <div class="status-ok">✅ Coordinator Service: Online</div>
      <div>📊 <a href="/api/health">Health Check</a></div>
      <div>🕐 <a href="/api/time">Time Service</a></div>
    </div>

    <div class="section">
      <h3>Repository Management</h3>
      <div>📂 <a href="/api/repository">List Repositories</a></div>
      <button onclick="syncRepositories()">🔄 Sync All</button>
      <button onclick="browseRepositories()">🗂️ Browse Files</button>
    </div>

    <div class="section">
      <h3>Instance Coordination</h3>
      <div>🤖 <a href="/api/instances">Active Instances</a></div>
      <div>Connected: <span id="instance-count">0</span></div>
    </div>

    <div class="section">
      <h3>Context Updates</h3>
      <div>📝 Recent Updates: <span id="context-count">0</span></div>
      <button onclick="viewContextHistory()">📋 View History</button>
    </div>

    <script>
      function syncRepositories() {
        alert('Repository sync functionality coming soon!');
      }

      function browseRepositories() {
        window.open('/api/repository', '_blank');
      }

      function viewContextHistory() {
        alert('Context history viewer coming soon!');
      }

      // Update counters
      fetch('/api/instances')
        .then(r => r.json())
        .then(data => {
          document.getElementById('instance-count').textContent = data.count || 0;
        })
        .catch(e => console.log('Failed to load instance count'));
    </script>
  </body>
  </html>
  """

  res.send html

# Static file serving for repository browsing
app.use '/static', express.static(REPO_PATH)

# Start server
server = app.listen PORT, ->
  console.log """
  🔗 ClaudeLink Coordinator Started

  Port: #{PORT}
  Environment: #{process.env.NODE_ENV or 'development'}
  Repository Path: #{REPO_PATH}
  Vault Server: #{VAULT_SERVER}

  API Endpoints:
    Health: http://localhost:#{PORT}/api/health
    Time: http://localhost:#{PORT}/api/time
    Repositories: http://localhost:#{PORT}/api/repository
    Admin: http://localhost:#{PORT}/admin

  Response Format: YAML (default) or JSON (with Accept: application/json header)
  """

# Graceful shutdown
process.on 'SIGTERM', ->
  console.log 'Received SIGTERM, shutting down gracefully...'
  server.close ->
    console.log 'Server closed'
    process.exit 0

process.on 'SIGINT', ->
  console.log 'Received SIGINT, shutting down gracefully...'
  server.close ->
    console.log 'Server closed'
    process.exit 0
