# Race-based SSE testing using EventSource
# Tests SSE endpoints without hanging on open connections

{ EventSource } = require 'eventsource'

console.log 'Starting race-based SSE tests...'

# Promise-based SSE test that resolves quickly
startSSETest = (url, headers = {}) ->
  new Promise (resolve, reject) ->
    try
      # Create EventSource with custom headers if provided
      options = {}
      if Object.keys(headers).length > 0
        options.headers = headers
      
      evtSource = new EventSource url, options
      
      # Store reference for cleanup
      resolve.evtSource = evtSource
      
      evtSource.addEventListener 'open', ->
        resolve { 
          result: 'connected'
          status: 200
          message: 'SSE connection opened successfully'
        }
      
      evtSource.addEventListener 'error', (event) ->
        resolve { 
          result: 'error'
          status: event.code or 500
          message: event.message or 'SSE connection failed'
        }
      
      evtSource.addEventListener 'message', (event) ->
        resolve { 
          result: 'message_received'
          status: 200
          data: event.data
          message: 'Received SSE message'
        }
      
    catch error
      resolve {
        result: 'exception'
        status: 500
        message: error.message
      }

# Timeout promise
sleepTest = (ms) ->
  new Promise (resolve) ->
    setTimeout ->
      resolve { 
        result: 'timeout'
        status: 408
        message: "Test timed out after #{ms}ms"
      }
    , ms

# Main test function using race pattern
testSSEEndpoint = (url, headers = {}, timeoutMs = 3000) ->
  console.log "Testing SSE endpoint: #{url}"
  
  testHandle = startSSETest url, headers
  sleepHandle = sleepTest timeoutMs
  
  try
    winner = await Promise.race [testHandle, sleepHandle]
    
    # Clean up EventSource connection
    testHandle.evtSource?.close()
    
    return winner
    
  catch error
    # Clean up on any error
    testHandle.evtSource?.close()
    return {
      result: 'exception'
      status: 500
      message: error.message
    }

# Test suite
runTests = ->
  console.log '\n=== Race-based SSE Test Suite ==='
  
  tests = [
    {
      name: 'Unauthenticated SSE request should fail'
      url: 'http://localhost:8080/api/mcp-sse/sse'
      expectStatus: 401
      expectResult: 'error'
    },
    {
      name: 'Invalid Bearer token should fail'  
      url: 'http://localhost:8080/api/mcp-sse/sse'
      headers: { 'Authorization': 'Bearer invalid-token' }
      expectStatus: 401
      expectResult: 'error'
    },
    {
      name: 'Non-existent endpoint should fail'
      url: 'http://localhost:8080/api/mcp-sse/nonexistent'
      expectStatus: 404
      expectResult: 'error'
    }
  ]
  
  results = []
  
  for test in tests
    console.log "\\n#{test.name}..."
    
    result = await testSSEEndpoint test.url, test.headers, 2000
    
    success = if test.expectStatus
      result.status is test.expectStatus
    else if test.expectResult  
      result.result is test.expectResult
    else
      result.result isnt 'timeout' and result.result isnt 'exception'
    
    if success
      console.log "✓ PASS: #{result.message} (#{result.status})"
    else
      console.log "✗ FAIL: Expected #{test.expectResult or test.expectStatus}, got #{result.result} (#{result.status})"
      console.log "  Message: #{result.message}"
    
    results.push { test: test.name, success, result }
  
  # Summary
  passed = results.filter((r) -> r.success).length
  total = results.length
  
  console.log "\\n" + "=".repeat(50)
  console.log "SSE Race Tests: #{passed}/#{total} passed"
  
  if passed is total
    console.log "✓ All tests passed!"
    process.exit 0
  else
    console.log "✗ Some tests failed"
    process.exit 1

# Run the tests
runTests().catch (error) ->
  console.error "Test runner failed: #{error.message}"
  process.exit 1