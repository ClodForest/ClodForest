# FILENAME: { ClodForest/src/coordinator/lib/mcp/capabilities.coffee }
# MCP Server Capabilities
# Defines what features this MCP server supports

config = require '../config'

# Get server capabilities
getCapabilities = ->
  # Protocol version
  protocolVersion: '2025-06-18'
  
  # Server info (Implementation interface)
  serverInfo:
    name:    'clodforest-mcp'
    title:   'ClodForest MCP Server'
    version: config.VERSION
  
  # Capabilities this server provides (ServerCapabilities interface)
  capabilities:
    # Resources - expose ClodForest data
    resources:
      subscribe: false    # We don't support subscriptions
      listChanged: false  # We don't push updates
    
    # Tools - expose ClodForest operations (CRITICAL FOR CLAUDE.AI!)
    tools:
      listChanged: false  # We don't push updates (subscribe not supported for tools)
    
    # Prompts - provide workflow templates
    prompts:
      listChanged: false  # We don't push updates (subscribe not supported for prompts)
    
    # Logging capability for debugging
    logging: {}
    
    # Completions - we don't support autocompletion yet
    # completions: {}
    
    # We don't support client features yet
    # sampling: false
    # roots: false
    # elicitation: false

module.exports = { getCapabilities }
