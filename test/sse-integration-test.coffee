# Real SSE integration test - actually tests the SSE endpoints
# Tests both authentication and SSE protocol functionality

http = require 'http'
https = require 'https'
EventSource = require 'eventsource'

# Test configuration
TEST_BASE_URL = 'http://localhost:8080'
TEST_CLIENT_ID = 'mcp-inspector'

console.log 'Starting SSE integration test...'

# Helper to make HTTP requests with timeout for SSE
makeRequest = (options, data = null, timeout = 2000) ->
  new Promise (resolve, reject) ->
    protocol = if options.protocol is 'https:' then https else http
    req = protocol.request options, (res) ->
      body = ''
      
      # For SSE streams, resolve after getting headers and initial data
      if res.headers['content-type']?.includes('text/event-stream')
        setTimeout ->
          resolve
            status: res.statusCode
            headers: res.headers
            body: body
            json: -> null
        , 100
      
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', ->
        resolve
          status: res.statusCode
          headers: res.headers
          body: body
          json: ->
            try
              JSON.parse body
            catch
              null

    req.on 'error', reject
    
    # Set timeout for non-SSE requests
    req.setTimeout timeout, ->
      req.destroy()
      reject new Error 'Request timeout'
    
    if data
      req.write data
    req.end()

# Test 1: SSE endpoint should require authentication
testAuthRequired = ->
  console.log '\n1. Testing SSE endpoint requires authentication...'
  
  # Test with no auth header - should get 401
  options =
    hostname: 'localhost'
    port: 8080
    path: '/api/mcp-sse/sse'
    method: 'GET'
    headers:
      'Accept': 'text/event-stream'
  
  try
    # Use a very short timeout to just check initial response
    response = await makeRequest options, null, 500
    if response.status is 401
      console.log '✓ SSE endpoint correctly requires authentication'
      return true
    else
      console.log "✗ Expected 401, got #{response.status}"
      console.log "Headers:", response.headers
      return false
  catch error
    if error.message is 'Request timeout'
      console.log "✗ Request timed out - endpoint may be allowing unauthenticated access"
      return false
    else
      console.log "✗ Request failed: #{error.message}"
      return false

# Test 2: Messages endpoint should require authentication
testMessagesAuthRequired = ->
  console.log '\n2. Testing messages endpoint requires authentication...'
  
  options =
    hostname: 'localhost'
    port: 8080
    path: '/api/mcp-sse/messages'
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Accept': 'application/json'
  
  data = JSON.stringify
    jsonrpc: '2.0'
    method: 'initialize'
    id: 1
    params:
      protocolVersion: '2024-11-05'
      capabilities: {}
      clientInfo:
        name: 'test-client'
        version: '1.0.0'
  
  try
    response = await makeRequest options, data
    if response.status is 401
      console.log '✓ Messages endpoint correctly requires authentication'
      return true
    else
      console.log "✗ Expected 401, got #{response.status}"
      return false
  catch error
    console.log "✗ Request failed: #{error.message}"
    return false

# Test 3: Service discovery shows SSE endpoints
testServiceDiscovery = ->
  console.log '\n3. Testing service discovery includes SSE endpoints...'
  
  options =
    hostname: 'localhost'
    port: 8080
    path: '/'
    method: 'GET'
    headers:
      'Accept': 'application/json'
  
  try
    response = await makeRequest options
    if response.status is 200
      data = response.json()
      if data?.transport?.sse and data.transport.sse.includes('/api/mcp-sse/sse')
        console.log '✓ Service discovery includes SSE transport endpoint'
        return true
      else
        console.log '✗ Service discovery missing SSE transport info'
        console.log 'Response:', JSON.stringify(data, null, 2)
        return false
    else
      console.log "✗ Expected 200, got #{response.status}"
      return false
  catch error
    console.log "✗ Request failed: #{error.message}"
    return false

# Test 4: Server handles malformed SSE requests gracefully
testMalformedRequests = ->
  console.log '\n4. Testing malformed SSE requests...'
  
  # Test without Accept header
  options =
    hostname: 'localhost'
    port: 8080
    path: '/api/mcp-sse/sse'
    method: 'GET'
    headers:
      'Authorization': 'Bearer invalid-token'
  
  try
    response = await makeRequest options
    # Should get 401 for invalid token, not crash
    if response.status >= 400 and response.status < 500
      console.log '✓ Server handles malformed SSE requests gracefully'
      return true
    else
      console.log "✗ Unexpected response: #{response.status}"
      return false
  catch error
    console.log "✗ Request failed: #{error.message}"
    return false

# Test 5: Messages endpoint requires sessionId
testMessagesSessionId = ->
  console.log '\n5. Testing messages endpoint requires sessionId...'
  
  options =
    hostname: 'localhost'
    port: 8080
    path: '/api/mcp-sse/messages'
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Accept': 'application/json'
      'Authorization': 'Bearer invalid-token'
  
  data = JSON.stringify
    jsonrpc: '2.0'
    method: 'tools/list'
    id: 1
  
  try
    response = await makeRequest options
    # Should get 400 for missing sessionId (before auth check)
    if response.status is 400
      responseData = response.json()
      if responseData?.error and typeof responseData.error is 'string' and responseData.error.indexOf('sessionId') >= 0
        console.log '✓ Messages endpoint correctly requires sessionId'
        return true
      else
        console.log '✗ Wrong error message for missing sessionId'
        console.log 'Response:', JSON.stringify(responseData, null, 2)
        return false
    else
      console.log "✗ Expected 400, got #{response.status}"
      return false
  catch error
    console.log "✗ Request failed: #{error.message}"
    return false

# Run all tests
runTests = ->
  console.log 'Running SSE integration tests against running server...'
  
  tests = [
    testAuthRequired
    testMessagesAuthRequired
    testServiceDiscovery
    testMalformedRequests
    testMessagesSessionId
  ]
  
  results = []
  for test in tests
    try
      result = await test()
      results.push result
    catch error
      console.log "✗ Test failed with error: #{error.message}"
      results.push false
  
  passed = results.filter((r) -> r).length
  total = results.length
  
  console.log "\n" + "=".repeat(50)
  console.log "SSE Integration Test Results: #{passed}/#{total} passed"
  
  if passed is total
    console.log "✓ All tests passed!"
    process.exit 0
  else
    console.log "✗ Some tests failed"
    process.exit 1

# Start tests
runTests().catch (error) ->
  console.error "Test runner failed: #{error.message}"
  process.exit 1