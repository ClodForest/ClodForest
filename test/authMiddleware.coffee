authenticate = require '../src/middleware/auth'
{ testMiddleware } = require './util/misc'

console.log 'Testing auth middleware...'

# Test cases using race pattern
testPublicPath = (path) ->
  result = await testMiddleware authenticate, path, 500

  if result.result is 'next'
    console.log "✓ #{path} correctly allows access (public)"
    return true
  else
    console.log "✗ #{path} should call next(), got: #{result.message}"
    return false

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

# Run tests
runTests = ->
  console.log '\\nPublic paths:'
  publicResults = []
  for path in ['/api/health', '/oauth/token', '/.well-known/jwks', '/']
    result = await testPublicPath path
    publicResults.push result

  console.log '\\nProtected paths:'
  protectedResults = []
  for path in ['/api/mcp', '/api/mcp-sse', '/api/mcp-sse/messages', '/api/unknown', '/admin/dashboard']
    result = await testProtectedPath path
    protectedResults.push result

  # Results
  allResults = publicResults.concat protectedResults
  passed = allResults.filter((r) -> r).length
  total = allResults.length

  console.log "\\n" + "=".repeat(40)
  console.log "Auth Tests: #{passed}/#{total} passed"

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
