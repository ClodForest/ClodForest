# Test utility functions extracted from authMiddleware.coffee

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

testMiddleware = (middleware, path, timeoutMs = 1000) ->
  new Promise (resolve) ->
    req = makeRequestMock path

    { res,                   statusPromise } = makeResponseMock()
    { callback: next, promise: nextPromise } = makeCallbackWithPromise()

    timeoutPromise = makeTimeout timeoutMs

    # Call middleware
    try
      if 'function' isnt typeof res.status
        throw new Error "IMPOSSIBRU: res = " + JSON.stringify res, null, 2

      middlewareResult = middleware req, res, next

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

module.exports = {
  makeCallback
  makeCallbackWithPromise
  makeResponseMock
  makeTimeout
  makeRequestMock
  testMiddleware
}