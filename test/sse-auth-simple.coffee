authenticate = require '../src/middleware/auth'
{ testMiddleware } = require './util/misc'

console.log 'Testing SSE auth protection...'

# Test helper functions (copied from authMiddleware.coffee pattern)
testProtectedPath = (path) ->
  result = await testMiddleware authenticate, path, 500

  if result.result is 'status' and result.calledWith[0] is 401
    console.log "✓ #{path} correctly requires auth (401)"
    return true
  else if result.result is 'status'
    console.log "✗ #{path} called status(#{JSON.stringify result.calledWith[0]}) instead of 401"
    return false
  else
    console.log "✗ #{path} should call status(401), got: #{result.message}"
    return false

testPublicPath = (path) ->
  result = await testMiddleware authenticate, path, 500

  if result.result is 'next'
    console.log "✓ #{path} correctly allows access (public)"
    return true
  else
    console.log "✗ #{path} should call next(), got: #{result.message}"
    return false

# Run tests
runTests = ->
  console.log '\nTesting SSE paths should be protected:'
  protectedResults = []
  for path in ['/api/mcp-sse/sse', '/api/mcp-sse/messages']
    result = await testProtectedPath path
    protectedResults.push result

  console.log '\nTesting public paths should pass:'
  publicResults = []
  for path in ['/api/health', '/']
    result = await testPublicPath path
    publicResults.push result

  # Results
  allResults = protectedResults.concat publicResults
  passed = allResults.filter((r) -> r).length
  total = allResults.length

  console.log "\n" + "=".repeat(40)
  console.log "SSE Auth Tests: #{passed}/#{total} passed"

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