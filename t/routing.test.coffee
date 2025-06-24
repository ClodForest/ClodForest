# Routing Module Tests

kava = require 'kava'
http = require 'http'
express = require 'express'
routing = require '../src/coordinator/lib/routing'
middleware = require '../src/coordinator/lib/middleware'

kava.suite 'Routing Module', (suite, test) ->

  # Create test app and server for each test
  createTestServer = (callback) ->
    app = express()
    middleware.setup(app)
    routing.setup(app)
    server = app.listen 0, -> # Use port 0 for random available port
      port = server.address().port
      callback(server, port)

  # Helper to make HTTP requests
  makeRequest = (port, options, callback) ->
    reqOptions =
      hostname: 'localhost'
      port: port
      method: options.method or 'GET'
      path: options.path or '/'
      headers: options.headers or {}

    req = http.request reqOptions, (res) ->
      body = ''
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', -> callback(null, res, body)

    req.on 'error', callback

    if options.data
      req.write(JSON.stringify(options.data))

    req.end()

  test 'should export setup function', (done) ->
    if typeof routing.setup isnt 'function'
      return done(new Error('Routing module must export setup function'))
    done()

  test 'should setup routes without errors', (done) ->
    try
      createTestServer (server, port) ->
        server.close()
        done()
    catch error
      done(error)

  test 'root endpoint should return welcome data', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        # Should return JSON by default (middleware preference)
        if not body or (not body.includes('"service"') and not body.includes('service:'))
          return done(new Error('Should return welcome data (JSON or YAML)'))

        done()

  test 'root endpoint should return HTML when requested', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {
        path: '/'
        headers: {'Accept': 'text/html'}
      }, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        if not body.includes('<!DOCTYPE html>')
          return done(new Error('Should return HTML'))

        if not body.includes('ClodForest Coordinator')
          return done(new Error('Should include service name'))

        done()

  test 'health endpoint should return health data', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/api/health/'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        # Should contain health status (JSON or YAML format)
        if not body or (not body.includes('"status"') and not body.includes('status:'))
          return done(new Error('Should return health status'))

        done()

  test 'time endpoint should return time data', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/api/time/'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        # Should contain timestamp (JSON or YAML format)
        if not body or (not body.includes('"timestamp"') and not body.includes('timestamp:'))
          return done(new Error('Should return timestamp'))

        done()

  test 'repository endpoint should return repository data', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/api/repo'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        # Should contain repositories or error (JSON or YAML format)
        if not body or (not body.includes('"repositories"') and not body.includes('repositories:') and not body.includes('"error"') and not body.includes('error:'))
          return done(new Error('Should return repository data or error'))

        done()

  test 'instances endpoint should return instances data', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/api/instances'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        # Should contain instances data (JSON or YAML format)
        if not body or (not body.includes('"instances"') and not body.includes('instances:'))
          return done(new Error('Should return instances data'))

        done()

  test 'admin endpoint should return admin interface', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/admin'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        if not body.includes('ClodForest Admin')
          return done(new Error('Should return admin interface'))

        done()

  test 'should handle 404 for unknown routes', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {path: '/nonexistent-route'}, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 404
          return done(new Error("Expected 404, got #{res.statusCode}"))

        # Should return JSON error
        try
          data = JSON.parse(body)
          if not data.error or data.error isnt 'Not Found'
            return done(new Error('Should return proper 404 error'))
        catch parseError
          return done(new Error('Should return JSON error response'))

        done()

  test 'instance registration should work', (done) ->
    createTestServer (server, port) ->
      testInstance =
        id: 'test-instance'
        name: 'Test Instance'
        version: '1.0.0'

      makeRequest port, {
        method: 'POST'
        path: '/api/instances/register'
        headers: {'Content-Type': 'application/json'}
        data: testInstance
      }, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        try
          data = JSON.parse(body)
          if data.status isnt 'registered'
            return done(new Error('Should return registration confirmation'))
        catch parseError
          return done(new Error('Should return JSON response'))

        done()

  test 'should handle JSON Accept header', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {
        path: '/api/health/'
        headers: {'Accept': 'application/json'}
      }, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        try
          data = JSON.parse(body)
          if not data.status
            return done(new Error('Should return JSON health data'))
        catch parseError
          return done(new Error('Should return valid JSON'))

        done()

  test 'should handle YAML Accept header', (done) ->
    createTestServer (server, port) ->
      makeRequest port, {
        path: '/api/health/'
        headers: {'Accept': 'application/yaml'}
      }, (err, res, body) ->
        server.close()
        if err
          return done(err)

        if res.statusCode isnt 200
          return done(new Error("Expected 200, got #{res.statusCode}"))

        if not body.includes('status:')
          return done(new Error('Should return YAML health data'))

        done()
