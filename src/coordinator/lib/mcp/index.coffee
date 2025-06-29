# FILENAME: { ClodForest/src/coordinator/lib/mcp/index.coffee }
# Model Context Protocol (MCP) Implementation
# Main module for processing MCP JSON-RPC requests

jsonrpc      = require './jsonrpc'
methods      = require './methods'
capabilities = require './capabilities'

# Process MCP JSON-RPC request
processJsonRpc = (requestBody, callback) ->
  jsonrpc.processJsonRpc requestBody, callback

module.exports = {
  processJsonRpc
  capabilities: capabilities.getCapabilities()
}
