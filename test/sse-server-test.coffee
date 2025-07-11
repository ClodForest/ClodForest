# Test SSE server functionality
# Basic smoke test to ensure SSE server starts without errors

{ createSseRouter } = require '../src/mcp/sse-server'
express = require 'express'

console.log 'Testing SSE server creation...'

try
  # Create SSE router
  sseRouter = createSseRouter()
  console.log '✓ SSE router created successfully'
  
  # Create test Express app
  app = express()
  app.use '/api/mcp', sseRouter
  console.log '✓ SSE router integrated with Express'
  
  console.log '\nSSE server tests passed!'
  process.exit 0
  
catch error
  console.error '✗ SSE server test failed:', error.message
  console.error error.stack
  process.exit 1