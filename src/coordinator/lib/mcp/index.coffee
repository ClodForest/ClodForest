# FILENAME: { ClodForest/src/coordinator/lib/mcp/index.coffee }
# Model Context Protocol (MCP) Implementation
# Main module for processing MCP JSON-RPC requests

jsonrpc      = require './jsonrpc'
methods      = require './methods'
capabilities = require './capabilities'

# Process MCP JSON-RPC request
processJsonRpc = (requestBody, req, callback) ->
  # Handle both 2 and 3 parameter calls for backward compatibility
  if typeof req is 'function'
    callback = req
    req = null
  
  jsonrpc.processJsonRpc requestBody, req, callback

module.exports = {
  processJsonRpc
  capabilities: capabilities.getCapabilities()
}
