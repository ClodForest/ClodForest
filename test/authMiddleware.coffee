authenticate = require '../src/middleware/auth'

console.log 'Testing auth middleware...'


makeCallback = ->
  calledWith = undefined

  callback        = (args...) -> calledWith = args
  callback.called = -> if calledWith then {calledWith} else false
  callback


makeCallbackWithPromise = (callbackName = 'next') ->
  callback = null

  promise = new Promise (resolve) ->
    callback = (calledWith...) ->
      resolve { result: callbackName, calledWith, message: "#{callbackName}(#{JSON.stringify(calledWith)[1..-2]})"}

  {callback, promise}


makeResponseMock = ->
  { callback: status
    promise:  statusPromise
  } = makeCallbackWithPromise 'status'

  status.json = ->

  return { res: {status}, statusPromise }


makeTimeout = (ms) ->
  new Promise (resolve) ->
    setTimeout ->
      resolve { result: 'timeout', message: "Test timed out after #{ms}ms" }
    , ms

makeRequestMock = (path) ->
  path:        path
  method:      'GET'
  url:         path
  originalUrl: path
  headers:     {}
  ip:          '127.0.0.1'
  get:         -> 'test'

testMiddleware = (path, timeoutMs = 1000) ->
  new Promise (resolve) ->
    req = makeRequestMock path

    { res,                   statusPromise } = makeResponseMock()
    { callback: next, promise: nextPromise } = makeCallbackWithPromise()

    timeoutPromise = makeTimeout timeoutMs

    # Call middleware
    try
      if 'function' isnt typeof res.status
        throw new Error "IMPOSSIBRU: res = " + JSON.stringify res, null, 2

      middlewareResult = authenticate req, res, next

      # If middleware returns a promise, include it in the race
      if middlewareResult?.then
        Promise.race([nextPromise, statusPromise, timeoutPromise, middlewareResult])
          .then resolve
      else
        # Synchronous middleware - race immediate results
        Promise.race([nextPromise, statusPromise, timeoutPromise])
          .then resolve

    catch error
      resolve { result: 'error', message: error.message }

# Test cases using race pattern
testPublicPath = (path) ->
  result = await testMiddleware path, 500

  if result.result is 'next'
    console.log "✓ #{path} correctly allows access (public)"
    return true
  else
    console.log "✗ #{path} should call next(), got: #{result.message}"
    return false

testProtectedPath = (path) ->
  result = await testMiddleware path, 500

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
  for path in ['/api/mcp', '/api/mcp-sse/sse', '/api/mcp-sse/messages', '/api/unknown', '/admin/dashboard']
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
