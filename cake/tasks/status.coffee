# FILENAME: { ClodForest/cake/tasks/status.coffee }
# Status and health check tasks

# Simple console formatting without external dependencies
{paths, exists} = require '../lib/paths'
platform = require '../lib/platform'

checkFile = (filePath, description) ->
  if exists filePath
    console.log "  ✅ #{description}"
    true
  else
    console.log "  ❌ #{description}"
    false

showStatus = ->
  console.log """
  ClodForest Project Status

  Core Files:
  """
  
  checkFile paths.entryPoint, "Entry point: #{paths.entryPoint}"
  checkFile paths.config, "Configuration: #{paths.config}"
  
  console.log "\nDirectories:"
  checkFile paths.src, 'Source directory'
  checkFile paths.state, 'State directory'
  checkFile paths.data, 'Data directory'
  checkFile paths.logs, 'Logs directory'
  
  console.log "\nKey Modules:"
  checkFile "#{paths.src}/oauth/oidc-provider.coffee", 'OAuth2/OIDC Provider'
  checkFile "#{paths.src}/mcp/server.coffee", 'MCP Server'
  checkFile "#{paths.src}/lib/logger.coffee", 'Logger'
  
  console.log "\nPlatform:"
  console.log "  📋 Detected: #{platform.detect()}"
  console.log "  🖥️  Node.js: #{process.version}"
  console.log "  ☕ CoffeeScript: Available" if exists "#{paths.root}/node_modules/coffeescript"

module.exports = {showStatus}