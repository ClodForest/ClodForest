# FILENAME: { ClodForest/src/mcp/server.coffee }
# MCP server setup and handler

{ Server }                                    = require '@modelcontextprotocol/sdk/server/index.js'
{ StdioServerTransport }                      = require '@modelcontextprotocol/sdk/server/stdio.js'
{ CallToolRequestSchema, ListToolsRequestSchema } = require '@modelcontextprotocol/sdk/types.js'
stateTools = require './tools/state'

# Create MCP server instance
server = new Server(
  {
    name:    'clodforest-mcp-server'
    version: '1.0.0'
  },
  {
    capabilities:
      tools: {}
  }
)

# Register state management tools
server.setRequestHandler ListToolsRequestSchema, ->
  tools: [
    name: 'read_state_file'
    description: 'Read files from the state directory'
    inputSchema:
      type: 'object'
      properties:
        path:
          type: 'string'
          description: 'Path to the file within the state directory'
      required: ['path']
  ,
    name: 'write_state_file'
    description: 'Write files to the state directory'
    inputSchema:
      type: 'object'
      properties:
        path:
          type: 'string'
          description: 'Path to the file within the state directory'
        content:
          type: 'string'
          description: 'Content to write to the file'
      required: ['path', 'content']
  ,
    name: 'list_state_files'
    description: 'List files and directories in the state directory'
    inputSchema:
      type: 'object'
      properties:
        path:
          type: 'string'
          description: 'Path within the state directory to list (defaults to root)'
          default: '.'
  ]

# Handle tool calls
server.setRequestHandler CallToolRequestSchema, (request) ->
  { name, arguments: args } = request.params

  try
    switch name
      when 'read_state_file'
        await stateTools.readStateFile args.path
      
      when 'write_state_file'
        await stateTools.writeStateFile args.path, args.content
      
      when 'list_state_files'
        await stateTools.listStateFiles args.path or '.'
      
      else
        throw new Error "Unknown tool: #{name}"
  catch error
    console.error "Tool execution error for #{name}:", error
    throw error

# Express middleware to handle MCP over HTTP
mcpHandler = (req, res) ->
  try
    # Ensure this is a POST request with JSON content
    if req.method isnt 'POST'
      return res.status(405).json
        jsonrpc: '2.0'
        error:
          code:    -32601
          message: 'Method not allowed'
        id: null

    if not req.body or typeof req.body isnt 'object'
      return res.status(400).json
        jsonrpc: '2.0'
        error:
          code:    -32700
          message: 'Parse error'
        id: null

    # Validate JSON-RPC 2.0 format
    { jsonrpc, method, params, id } = req.body
    
    if jsonrpc isnt '2.0'
      return res.status(400).json
        jsonrpc: '2.0'
        error:
          code:    -32600
          message: 'Invalid Request - jsonrpc must be "2.0"'
        id: id or null

    if not method or typeof method isnt 'string'
      return res.status(400).json
        jsonrpc: '2.0'
        error:
          code:    -32600
          message: 'Invalid Request - method is required'
        id: id or null

    # Handle MCP methods
    if method is 'initialize'
      result =
        protocolVersion: '2025-06-18'
        capabilities:
          tools: {}
        serverInfo:
          name:    'clodforest-mcp-server'
          version: '1.0.0'
    else if method is 'tools/list'
      toolsResponse = await server.request { method: 'tools/list', params: params or {} }, ListToolsRequestSchema
      result = toolsResponse
    else if method is 'tools/call'
      unless params?.name
        throw new Error 'Tool name is required'
      toolResponse = await server.request { 
        method: 'tools/call'
        params: params 
      }, CallToolRequestSchema
      result = toolResponse
    else
      return res.status(400).json
        jsonrpc: '2.0'
        error:
          code:    -32601
          message: "Method not found: #{method}"
        id: id or null

    # Return successful response
    res.json
      jsonrpc: '2.0'
      result:  result
      id:      id or null

  catch error
    console.error 'MCP handler error:', error
    
    res.status(500).json
      jsonrpc: '2.0'
      error:
        code:    -32603
        message: 'Internal error'
        data:    if process.env.NODE_ENV is 'development' then error.message else undefined
      id: req.body?.id or null

module.exports = mcpHandler
