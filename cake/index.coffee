# FILENAME: { ClodForest/cake/index.coffee }
# Main task orchestrator

# Simple console formatting without external dependencies

# Import tasks
{setup} = require './tasks/setup'
{startDev, startProduction} = require './tasks/dev'
{install} = require './tasks/install'
{runTests, debugMcpInspector} = require './tasks/test'
{showStatus} = require './tasks/status'
{runOrFail} = require './lib/exec'

# Task definitions
tasks =
  # Development tasks
  setup:
    description: 'Initialize configuration files'
    action: setup
    
  dev:
    description: 'Start development server with auto-restart'
    action: startDev
    
  start:
    description: 'Start production server'
    action: startProduction
    
  # Testing tasks
  test:
    description: 'Run all tests'
    action: runTests
    
  'debug:mcp-inspector':
    description: 'Run MCP Inspector OAuth2 debug server'
    action: debugMcpInspector
    
  # Installation tasks
  install:
    description: 'Install as system service (auto-detects platform)'
    action: install
    
  # Utility tasks
  status:
    description: 'Show current project status'
    action: showStatus
    
  clean:
    description: 'Clean temporary files'
    action: ->
      await runOrFail 'rm -f /tmp/clodforest /tmp/clodforest.service'
      console.log "✅ Cleanup complete"
      
  help:
    description: 'Show available tasks'
    action: ->
      console.log """
      ClodForest Coordinator Tasks

      Development:
      """
      
      for name, task of tasks when name in ['setup', 'dev', 'test', 'debug:mcp-inspector', 'status']
        console.log "  cake #{name.padEnd 20} - #{task.description}"
      
      console.log "\nProduction:"
      
      for name, task of tasks when name in ['start', 'install']
        console.log "  cake #{name.padEnd 20} - #{task.description}"
      
      console.log "\nMaintenance:"
      
      for name, task of tasks when name in ['clean', 'help']
        console.log "  cake #{name.padEnd 20} - #{task.description}"
      
      console.log """

      Examples:
        cake setup && cake dev      - Initialize and start development
        cake install                - Auto-install for current platform
        cake status                 - Check project health

      Platform Support:
        ✅ Linux (systemd)     ✅ FreeBSD     ✅ Devuan/SysV
        ⚠️  macOS (manual)     ❌ Windows
      """

# Export tasks for Cakefile
module.exports = tasks