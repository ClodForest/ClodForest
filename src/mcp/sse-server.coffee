# FILENAME: { ClodForest/src/mcp/sse-server.coffee }
# SSE-based MCP server implementation using the official SDK

{ Server: McpServer } = require '@modelcontextprotocol/sdk/server/index.js'
{ SSEServerTransport } = require '@modelcontextprotocol/sdk/server/sse.js'
express = require 'express'
{ logger } = require '../lib/logger'
stateTools = require './tools/state'

# Session storage for SSE connections
sessions = new Map()

# Create MCP server instance with proper SDK usage
createMcpServer = ->
  server = new McpServer(
    {
      name: 'clodforest-mcp-server'
      version: '1.0.0'
    },
    {
      capabilities:
        tools: {}
    }
  )

  # Register read_state_file tool
  server.setRequestHandler 'tools/call', (request) ->
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
      logger.error 'Tool execution error', { tool: name, error: error.message }
      throw error

  # Register tools list handler
  server.setRequestHandler 'tools/list', ->
    tools: [
      {
        name: 'read_state_file'
        description: 'Read files from the state directory'
        inputSchema:
          type: 'object'
          properties:
            path:
              type: 'string'
              description: 'Path to the file within the state directory'
          required: ['path']
      },
      {
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
      },
      {
        name: 'list_state_files'
        description: 'List files and directories in the state directory'
        inputSchema:
          type: 'object'
          properties:
            path:
              type: 'string'
              description: 'Path within the state directory to list (defaults to root)'
              default: '.'
      }
    ]

  server

# Create router for SSE endpoints
createSseRouter = ->
  router = express.Router()

  # GET endpoint to establish SSE stream at root path
  router.get '/', (req, res) ->
    logger.mcp 'SSE stream requested', {
      ip: req.ip
      userAgent: req.get('User-Agent')
    }

    try
      # Test basic SSE response first
      res.writeHead 200, {
        'Content-Type': 'text/event-stream'
        'Cache-Control': 'no-cache'
        'Connection': 'keep-alive'
      }
      
      res.write 'event: test\ndata: SSE endpoint working\n\n'
      
      logger.mcp 'SSE test response sent'

    catch error
      logger.error 'Failed to establish SSE connection', { error: error.message }
      unless res.headersSent
        res.status(500).json
          error: 'Failed to establish SSE connection'
          message: error.message

  # POST endpoint to receive messages
  router.post '/messages', (req, res) ->
    sessionId = req.query.sessionId
    
    unless sessionId
      return res.status(400).json
        error: 'Missing sessionId parameter'

    session = sessions.get sessionId
    unless session
      return res.status(404).json
        error: 'Session not found'

    logger.mcp 'Message received', {
      sessionId: sessionId
      method: req.body?.method
      id: req.body?.id
    }

    try
      # Handle the message through the transport
      # SSEServerTransport expects the parsed body to be passed
      await session.transport.handlePostMessage req, res, req.body
    catch error
      logger.error 'SSE message handling error', {
        sessionId: sessionId
        error: error.message
      }
      
      # Only send error response if headers haven't been sent
      unless res.headersSent
        res.status(500).json
          error: 'Internal server error'
          message: error.message

  # Clean up old sessions periodically (every 5 minutes)
  setInterval ->
    now = new Date()
    for [sessionId, session] from sessions
      # Remove sessions older than 30 minutes
      if now - session.createdAt > 30 * 60 * 1000
        logger.mcp 'Cleaning up old session', { sessionId }
        session.server.close().catch (err) ->
          logger.error 'Error closing old server', { sessionId, error: err.message }
        sessions.delete sessionId
  , 5 * 60 * 1000

  router

module.exports = { createSseRouter }