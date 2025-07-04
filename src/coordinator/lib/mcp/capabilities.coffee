# FILENAME: { ClodForest/src/coordinator/lib/mcp/capabilities.coffee }
# MCP Server Capabilities
# Defines what features this MCP server supports

config = require '../config'

# Get server capabilities
getCapabilities = ->
  # Protocol version
  protocolVersion: '2025-06-18'
  
  # Server info
  serverInfo:
    name:    'clodforest-mcp'
    version: config.VERSION
  
  # Capabilities this server provides
  capabilities:
    # Resources - expose ClodForest data
    resources:
      subscribe: false    # We don't support subscriptions
      listChanged: false  # We don't push updates
    
    # Tools - expose ClodForest operations (THIS IS KEY!)
    tools:
      subscribe: false    # We don't support subscriptions
      listChanged: false  # We don't push updates
    
    # Prompts - provide workflow templates
    prompts:
      subscribe: false    # We don't support subscriptions
      listChanged: false  # We don't push updates
    
    # Logging capability for debugging
    logging: {}
    
    # We don't support client features yet
    # sampling: false
    # roots: false
    # elicitation: false

module.exports = { getCapabilities }
