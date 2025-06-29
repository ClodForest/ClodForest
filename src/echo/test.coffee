#!/usr/bin/env coffee
# FILENAME: { ClodForest/src/echo/test.coffee }
# Simple test script for JSON-RPC Echo Server

http = require 'http'

# Test configuration
TEST_HOST = 'localhost'
TEST_PORT = 8081

# Test cases
testCases = [
  {
    name: 'Simple Echo'
    request:
      jsonrpc: '2.0'
      method: 'echo.simple'
      params: { message: 'Hello, World!' }
      id: 1
  }
  {
    name: 'Enhanced Echo'
    request:
      jsonrpc: '2.0'
      method: 'echo.enhanced'
      params: { test: 'data', number: 42 }
      id: 2
  }
  {
    name: 'Delay Echo'
    request:
      jsonrpc: '2.0'
      method: 'echo.delay'
      params: { message: 'Delayed!', delay_ms: 100 }
      id: 3
  }
  {
    name: 'Error Test'
    request:
      jsonrpc: '2.0'
      method: 'echo.error'
      params: { error_type: 'generic' }
      id: 4
  }
  {
    name: 'Method Not Found'
    request:
      jsonrpc: '2.0'
      method: 'nonexistent.method'
      params: {}
      id: 5
  }
]

# Make HTTP request
makeRequest = (testCase, callback) ->
  postData = JSON.stringify(testCase.request)
  
  options =
    hostname: TEST_HOST
    port:     TEST_PORT
    path:     '/rpc'
    method:   'POST'
    headers:
      'Content-Type':   'application/json'
      'Content-Length': Buffer.byteLength(postData)
  
  req = http.request options, (res) ->
    body = ''
    
    res.on 'data', (chunk) ->
      body += chunk
    
    res.on 'end', ->
      try
        response = JSON.parse(body)
        callback null, response
      catch error
        callback error, null
  
  req.on 'error', (error) ->
    callback error, null
  
  req.write postData
  req.end()

# Run tests
runTests = ->
  console.log "🧪 Testing JSON-RPC Echo Server on #{TEST_HOST}:#{TEST_PORT}"
  console.log "=" * 60
  
  testIndex = 0
  
  runNextTest = ->
    if testIndex >= testCases.length
      console.log "\n✅ All tests completed!"
      return
    
    testCase = testCases[testIndex]
    console.log "\n#{testIndex + 1}. #{testCase.name}"
    console.log "Request:  #{JSON.stringify(testCase.request)}"
    
    makeRequest testCase, (error, response) ->
      if error
        console.log "❌ Error: #{error.message}"
      else
        console.log "Response: #{JSON.stringify(response)}"
        
        # Basic validation
        if response.jsonrpc is '2.0' and response.id is testCase.request.id
          if response.result or response.error
            console.log "✅ Valid JSON-RPC response"
          else
            console.log "⚠️  Missing result or error"
        else
          console.log "⚠️  Invalid JSON-RPC format"
      
      testIndex++
      setTimeout runNextTest, 200  # Small delay between tests

  runNextTest()

# Health check first
checkHealth = ->
  options =
    hostname: TEST_HOST
    port:     TEST_PORT
    path:     '/health'
    method:   'GET'
  
  req = http.request options, (res) ->
    if res.statusCode is 200
      console.log "✅ Server is healthy"
      runTests()
    else
      console.log "❌ Server health check failed (status: #{res.statusCode})"
  
  req.on 'error', (error) ->
    console.log "❌ Cannot connect to server: #{error.message}"
    console.log "Make sure the server is running with: coffee src/echo/index.coffee"
  
  req.end()

# Start testing
console.log "Checking server health..."
checkHealth()
