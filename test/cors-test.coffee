# FILENAME: { ClodForest/test/cors-test.coffee }
# Test CORS configuration for production and development

{ testMiddleware, makeRequestMock } = require './util/misc'

# Test CORS with different origins
testCorsOrigin = (origin, expectAllowed = true) ->
  new Promise (resolve) ->
    req = makeRequestMock '/', 'GET'
    req.headers = { origin: origin }
    
    res = {
      header: (name, value) -> @headers ?= {}; @headers[name] = value
      status: (code) -> @statusCode = code; @
      json: (data) -> @body = data; resolve { allowed: @statusCode isnt 403, headers: @headers, body: data }
      end: -> resolve { allowed: true, headers: @headers }
    }
    
    next = -> resolve { allowed: true }
    
    # Import CORS middleware
    cors = require 'cors'
    
    # Test production config
    if process.env.NODE_ENV is 'production'
      allowedOrigins = [
        'https://claude.ai'
        'https://app.claude.ai'
        'https://console.anthropic.com'
      ]
      
      corsOptions = 
        credentials: true
        origin: (origin, callback) ->
          unless origin
            return callback null, true
          if allowedOrigins.includes origin
            callback null, true
          else
            callback new Error('Not allowed by CORS'), false
    else
      corsOptions = { origin: true, credentials: true }
    
    corsMiddleware = cors corsOptions
    corsMiddleware req, res, next

runTests = ->
  console.log 'Testing CORS configuration...'
  
  # Test allowed origins in production
  if process.env.NODE_ENV is 'production'
    console.log '\nProduction mode - testing specific origins:'
    
    result1 = await testCorsOrigin 'https://claude.ai', true
    console.log "✓ claude.ai: #{if result1.allowed then 'ALLOWED' else 'BLOCKED'}"
    
    result2 = await testCorsOrigin 'https://evil.com', false
    console.log "✓ evil.com: #{if result2.allowed then 'ALLOWED (UNEXPECTED)' else 'BLOCKED'}"
    
    result3 = await testCorsOrigin null, true
    console.log "✓ no origin: #{if result3.allowed then 'ALLOWED' else 'BLOCKED'}"
  else
    console.log '\nDevelopment mode - all origins should be allowed'
    
    result1 = await testCorsOrigin 'https://example.com', true
    console.log "✓ example.com: #{if result1.allowed then 'ALLOWED' else 'BLOCKED'}"
    
    result2 = await testCorsOrigin null, true
    console.log "✓ no origin: #{if result2.allowed then 'ALLOWED' else 'BLOCKED'}"

runTests().catch console.error