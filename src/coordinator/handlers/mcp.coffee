# FILENAME: { ClodForest/src/coordinator/handlers/mcp.coffee }
# Model Context Protocol (MCP) Handler
# Implements MCP server features for ClodForest

mcp = require '../lib/mcp'

handleRequest = (req, res) ->
  # Set appropriate content type for JSON-RPC
  res.setHeader 'Content-Type', 'application/json'
  
  # Handle OPTIONS for CORS
  if req.method is 'OPTIONS'
    res.status(200).end()
    return
  
  # Process JSON-RPC request
  try
    requestBody = if typeof req.body is 'string' then req.body else JSON.stringify(req.body)
    
    mcp.processJsonRpc requestBody, req, (response) ->
      if response
        res.json response
      else
        # No response for notifications
        res.status(204).end()
  
  catch error
    console.error 'MCP handler error:', error
    res.status(500).json
      jsonrpc: '2.0'
      error:
        code: -32603
        message: 'Internal error'
        data: error.message
      id: null

module.exports = { handleRequest }
