# ClodForest API Implementation Module
# Business logic for all API endpoints

fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'
config = require './config'

# In-memory instance tracking
instances = new Map()

# Welcome/root endpoint data
getWelcomeData = ->
  service:     config.SERVICE_NAME
  version:     config.VERSION
  status:      'operational'
  description: 'Coordination service for distributed Claude instances'
  timestamp:   new Date().toISOString()

  endpoints:
    health:     config.API_PATHS.HEALTH + '/'
    time:       config.API_PATHS.TIME + '/'
    repository: config.API_PATHS.REPO
    context:    config.API_PATHS.CONTEXT + '/update'
    instances:  config.API_PATHS.INSTANCES
    admin:      config.API_PATHS.ADMIN

  features: [
    'Time synchronization service'
    'Repository access and management'
    'Context update coordination'
    'Instance registration and discovery'
    'Administrative interface'
  ]

  documentation: 'https://clodforest.thatsnice.org/docs'
  support:       'robert@defore.st'

# Health check implementation
getHealthData = ->
  uptime = process.uptime()
  memUsage = process.memoryUsage()

  status:    'healthy'
  timestamp: new Date().toISOString()
  uptime:    "#{Math.floor(uptime)} seconds"

  memory:
    rss:       "#{Math.round(memUsage.rss / 1024 / 1024)} MB"
    heapUsed:  "#{Math.round(memUsage.heapUsed / 1024 / 1024)} MB"
    heapTotal: "#{Math.round(memUsage.heapTotal / 1024 / 1024)} MB"

  environment: config.getEnvironmentInfo()

  services:
    vaultServer:    config.VAULT_SERVER
    repositoryPath: config.REPO_PATH

# Time service implementation
getTimeData = (req) ->
  now = new Date()

  timestamp: now.toISOString()
  unix:      Math.floor(now.getTime() / 1000)
  timezone:  'UTC'

  formats:
    iso8601:      now.toISOString()
    rfc2822:      now.toUTCString()
    unix:         Math.floor(now.getTime() / 1000)
    milliseconds: now.getTime()

  requestor: req.get('X-ClaudeLink-Instance') or 'unknown'

# Repository listing implementation
getRepositoryData = ->
  try
    repositories = fs.readdirSync(config.REPO_PATH)
      .filter (item) ->
        itemPath = path.join(config.REPO_PATH, item)
        fs.statSync(itemPath).isDirectory()

    repositories: repositories
    count:        repositories.length
    path:         config.REPO_PATH
    server:       config.VAULT_SERVER
    timestamp:    new Date().toISOString()

  catch error
    error:     'Repository access failed'
    message:   error.message
    timestamp: new Date().toISOString()

# Repository browsing implementation
browseRepository = (repo, browsePath = '') ->
  fullPath = path.join(config.REPO_PATH, repo, browsePath)

  try
    items = fs.readdirSync(fullPath)
      .map (item) ->
        itemPath = path.join(fullPath, item)
        stat = fs.statSync(itemPath)

        name:     item
        type:     if stat.isDirectory() then 'directory' else 'file'
        size:     stat.size
        modified: stat.mtime.toISOString()

    repository: repo
    path:       browsePath
    items:      items
    count:      items.length
    timestamp:  new Date().toISOString()

  catch error
    error:      'Browse failed'
    message:    error.message
    repository: repo
    path:       browsePath
    timestamp:  new Date().toISOString()

# File reading implementation
readRepositoryFile = (repo, filePath) ->
  fullPath = path.join(config.REPO_PATH, repo, filePath)

  try
    content = fs.readFileSync(fullPath, 'utf8')
    stat = fs.statSync(fullPath)

    repository: repo
    file:       filePath
    content:    content
    size:       stat.size
    modified:   stat.mtime.toISOString()
    timestamp:  new Date().toISOString()

  catch error
    error:      'File read failed'
    message:    error.message
    repository: repo
    file:       filePath
    timestamp:  new Date().toISOString()

# Git operations implementation
executeGitCommand = (repo, command, args = [], callback) ->
  unless command in config.ALLOWED_GIT_COMMANDS
    return callback
      error:   'Git command not allowed'
      command: command
      allowed: config.ALLOWED_GIT_COMMANDS

  repoPath = path.join(config.REPO_PATH, repo)
  gitCommand = "git -C #{repoPath} #{command} #{args.join(' ')}"

  exec gitCommand, (error, stdout, stderr) ->
    gitData =
      repository: repo
      command:    command
      args:       args
      timestamp:  new Date().toISOString()

    if error
      gitData.error = error.message
      gitData.stderr = stderr
    else
      gitData.stdout = stdout
      gitData.stderr = stderr if stderr

    callback gitData

# Context update implementation (placeholder)
processContextUpdate = (req) ->
  instanceId = req.get('X-ClaudeLink-Instance') or 'unknown'
  {requestor, requests} = req.body

  status:       'received'
  requestor:    requestor or instanceId
  requestCount: requests?.length or 0
  timestamp:    new Date().toISOString()
  message:      'Context update processing not yet implemented'

# Instance tracking implementation
getInstancesData = ->
  instances: Array.from(instances.values())
  count:     instances.size
  timestamp: new Date().toISOString()

registerInstance = (instanceData) ->
  instances.set(instanceData.id, {
    ...instanceData
    lastSeen: new Date().toISOString()
  })

# Admin interface HTML generation
generateAdminHTML = ->
  isDev = config.isDevelopment

  """
  <!DOCTYPE html>
  <html>
  <head>
    <title>ClodForest Admin</title>
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
    <div class="header">🔗 ClodForest Admin Dashboard</div>

    #{if isDev then '<div class="status-warn">⚠️ Development Mode - Authentication Bypassed</div>' else ''}

    <div class="section">
      <h3>Service Status</h3>
      <div class="status-ok">✅ Coordinator Service: Online</div>
      <div>📊 <a href="#{config.API_PATHS.HEALTH}/">Health Check</a></div>
      <div>🕐 <a href="#{config.API_PATHS.TIME}/">Time Service</a></div>
    </div>

    <div class="section">
      <h3>Repository Management</h3>
      <div>📂 <a href="#{config.API_PATHS.REPO}">List Repositories</a></div>
      <button onclick="syncRepositories()">🔄 Sync All</button>
      <button onclick="browseRepositories()">🗂️ Browse Files</button>
    </div>

    <div class="section">
      <h3>Instance Coordination</h3>
      <div>🤖 <a href="#{config.API_PATHS.INSTANCES}">Active Instances</a></div>
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
        window.open('#{config.API_PATHS.REPO}', '_blank');
      }

      function viewContextHistory() {
        alert('Context history viewer coming soon!');
      }

      // Update counters
      fetch('#{config.API_PATHS.INSTANCES}')
        .then(r => r.json())
        .then(data => {
          document.getElementById('instance-count').textContent = data.count || 0;
        })
        .catch(e => console.log('Failed to load instance count'));
    </script>
  </body>
  </html>
  """

module.exports = {
  getWelcomeData
  getHealthData
  getTimeData
  getRepositoryData
  browseRepository
  readRepositoryFile
  executeGitCommand
  processContextUpdate
  getInstancesData
  registerInstance
  generateAdminHTML
}