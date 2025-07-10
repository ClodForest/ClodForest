# FILENAME: { ClodForest/cake/tasks/status.coffee }
# Status and health check tasks

# Try to load chalk, fall back to plain text if not available
try
  chalk = require 'chalk'
catch
  chalk =
    cyan:   (text) -> text
    green:  (text) -> text
    red:    (text) -> text
{paths, exists} = require '../lib/paths'
platform = require '../lib/platform'

checkFile = (filePath, description) ->
  if exists filePath
    console.log "  #{chalk.green '✅'} #{description}"
    true
  else
    console.log "  #{chalk.red '❌'} #{description}"
    false

showStatus = ->
  console.log """
  #{chalk.cyan 'ClodForest Project Status'}

  #{chalk.green 'Core Files:'}
  """
  
  checkFile paths.entryPoint, "Entry point: #{paths.entryPoint}"
  checkFile paths.config, "Configuration: #{paths.config}"
  
  console.log "\n#{chalk.green 'Directories:'}"
  checkFile paths.src, 'Source directory'
  checkFile paths.state, 'State directory'
  checkFile paths.data, 'Data directory'
  checkFile paths.logs, 'Logs directory'
  
  console.log "\n#{chalk.green 'Key Modules:'}"
  checkFile "#{paths.src}/oauth/oidc-provider.coffee", 'OAuth2/OIDC Provider'
  checkFile "#{paths.src}/mcp/server.coffee", 'MCP Server'
  checkFile "#{paths.src}/lib/logger.coffee", 'Logger'
  
  console.log "\n#{chalk.green 'Platform:'}"
  console.log "  📋 Detected: #{platform.detect()}"
  console.log "  🖥️  Node.js: #{process.version}"
  console.log "  ☕ CoffeeScript: Available" if exists "#{paths.root}/node_modules/coffeescript"

module.exports = {showStatus}