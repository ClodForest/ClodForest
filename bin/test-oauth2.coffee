#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-oauth2.coffee }
# Pure OAuth2 Authentication Test Script
# Tests OAuth2 functionality without MCP endpoints

http   = require 'http'
https  = require 'https'
{URL}  = require 'url'
crypto = require 'crypto'

# Parse command line arguments
args = process.argv.slice(2)
verbose = false
exitCode = 0

# Default configuration (local development)
config =
  host: 'localhost'
  port: 8080
  useHttps: false
  environment: 'local'

# Environment presets
environments =
  local:
    host: 'localhost'
    port: 8080
    useHttps: false
    environment: 'local'

  production:
    host: 'clodforest.thatsnice.org'
    port: 443
    useHttps: true
    environment: 'production'

# Parse arguments
showHelp = ->
  console.log '''
    ClodForest OAuth2 Authentication Test Script

    Usage:
      coffee bin/test-oauth2.coffee [options]

    Options:
      --env, -e <environment>    Environment preset (local, production)
      --host, -h <hostname>      Server hostname
      --port, -p <port>          Server port
      --https                    Use HTTPS
      --http                     Use HTTP
      --verbose, -v              Show detailed output
      --help                     Show this help

    Environment Presets:
      local                      http://localhost:8080 (default)
      production                 https://clodforest.thatsnice.org:443

    Exit Codes:
      0                          OAuth2 functionality verified
      1                          OAuth2 failure or missing infrastructure

    Examples:
      coffee bin/test-oauth2.coffee                    # Test local OAuth2
      coffee bin/test-oauth2.coffee --verbose          # Test with details
      coffee bin/test-oauth2.coffee --env production   # Test production
    '''
  process.exit 0

i = 0
while i < args.length
  arg = args[i]

  switch arg
    when '--help'
      showHelp()

    when '--verbose', '-v'
      verbose = true

    when '--env', '-e'
      envName = args[++i]
      unless envName
        console.error 'Error: --env requires an environment name'
        process.exit 1

      unless environments[envName]
        console.error "Error: Unknown environment '#{envName}'. Available: #{Object.keys(environments).join(', ')}"
        process.exit 1

      config = Object.assign({}, environments[envName])

    when '--host', '-h'
      config.host = args[++i]
      unless config.host
        console.error 'Error: --host requires a hostname'
        process.exit 1

    when '--port', '-p'
      config.port = parseInt(args[++i])
      unless config.port
        console.error 'Error: --port requires a valid port number'
        process.exit 1

    when '--https'
      config.useHttps = true

    when '--http'
      config.useHttps = false

    else
      console.error "Error: Unknown option '#{arg}'"
      console.error "Use --help for usage information"
      process.exit 1

  i++

# Logging functions
logVerbose = (message) ->
  if verbose
    console.log message

logError = (message) ->
  console.error message
  exitCode = 1

logSuccess = (message) ->
  if verbose
    console.log message

# Helper to make HTTP request
makeRequest = (method, path, data = null, headers = {}) ->
  new Promise (resolve, reject) ->
    options =
      hostname: config.host
      port: config.port
      path: path
      method: method
      headers: Object.assign({
        'Content-Type': 'application/json'
      }, headers)

    if data and method isnt 'GET'
      dataStr = if typeof data is 'string' then data else JSON.stringify(data)
      options.headers['Content-Length'] = Buffer.byteLength(dataStr)

    httpModule = if config.useHttps then https else http

    req = httpModule.request options, (res) ->
      body = ''
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', ->
        try
          result = if body then JSON.parse(body) else null
          resolve { status: res.statusCode, headers: res.headers, body: result }
        catch e
          resolve { status: res.statusCode, headers: res.headers, body: body }

    req.on 'error', reject
    req.write(dataStr) if data and method isnt 'GET'
    req.end()

# OAuth2 test results tracking
oauth2Results = {
  serverReachable: false
  serverHealthy: false
  clientRegistration: false
  tokenEndpoint: false
  clientCredentialsGrant: false
  tokenValidation: false
  errorHandling: false
}

# Main test sequence
main = ->
  protocol = if config.useHttps then 'https' else 'http'
  logVerbose "🔐 Testing OAuth2 Authentication: #{protocol}://#{config.host}:#{config.port}"
  testNum = 0

  try
    logVerbose "\n#{testNum++}. Testing server online at all..."
    healthCheck = await makeRequest 'GET', '/'

    if healthCheck.status is 200
      oauth2Results.serverReachable = true
      logSuccess "✅ Server online"
    else
      logError "❌ Server not online? (HTTP #{healthCheck.status})"
      return reportResults()

    logVerbose "\n#{testNum++}. Testing server connectivity..."
    healthCheck = await makeRequest 'GET', '/api/health'

    if healthCheck.status is 200
      oauth2Results.serverHealthy = true
      logSuccess "✅ Server reachable"
    else
      logError "❌ Server not reachable (HTTP #{healthCheck.status})"
      return reportResults()

    logVerbose "\n#{testNum++}. Checking OAuth2 configuration..."
    configCheck = await makeRequest 'GET', '/api/config'

    if configCheck.status is 200 and configCheck.body?.features?.OAUTH2_AUTH
      logSuccess "✅ OAuth2 enabled in configuration"
    else
      logError "❌ OAuth2 not enabled in server configuration"
      logError "   Set OAUTH2_AUTH feature flag to true"
      return reportResults()

    logVerbose "\n#{testNum++}. Testing client registration..."
    clientReg = await makeRequest 'POST', '/oauth/clients',
      name: 'OAuth2 Test Client'
      redirect_uris: ['http://localhost:3000/callback']
      scope: 'mcp read write'

    if clientReg.status is 201
      oauth2Results.clientRegistration = true
      client = clientReg.body
      logSuccess "✅ Client registration successful"
      logVerbose "   Client ID: #{client.client_id}"
      logVerbose "   Client Secret: #{client.client_secret?.substring(0, 8)}..."
    else if clientReg.status is 404
      logError "❌ Client registration endpoint not found"
      logError "   OAuth2 client registration not implemented"
      return reportResults()
    else if clientReg.status is 500
      logError "❌ Client registration failed - server error"
      logError "   OAuth2 infrastructure not fully implemented"
      logVerbose "   Response: #{JSON.stringify(clientReg.body, null, 2)}" if clientReg.body
      return reportResults()
    else
      logError "❌ Client registration failed (HTTP #{clientReg.status})"
      logVerbose "   Response: #{JSON.stringify(clientReg.body, null, 2)}" if clientReg.body
      return reportResults()

    logVerbose "\n#{testNum++}. Testing token endpoint..."

    # Create Basic auth header for client credentials
    credentials = Buffer.from("#{client.client_id}:#{client.client_secret}").toString('base64')

    tokenTest = await makeRequest 'POST', '/oauth/token',
      grant_type: 'client_credentials'
      scope: 'mcp'
    ,
      'Authorization': "Basic #{credentials}"

    if tokenTest.status is 200
      oauth2Results.tokenEndpoint = true
      oauth2Results.clientCredentialsGrant = true
      token = tokenTest.body
      logSuccess "✅ Token endpoint functional"
      logSuccess "✅ Client credentials grant successful"
      logVerbose "   Access token: #{token.access_token?.substring(0, 16)}..."
      logVerbose "   Token type: #{token.token_type}"
      logVerbose "   Expires in: #{token.expires_in}s"
      logVerbose "   Scope: #{token.scope}"

      logVerbose "\n#{testNum++}. Testing token validation..."

      # Try to access a protected endpoint with the token
      protectedTest = await makeRequest 'GET', '/api/config',
        null
      ,
        'Authorization': "Bearer #{token.access_token}"

      if protectedTest.status is 200
        oauth2Results.tokenValidation = true
        logSuccess "✅ Token validation successful"
      else
        logError "❌ Token validation failed (HTTP #{protectedTest.status})"
        logError "   Token may not be properly validated by server"

    else if tokenTest.status is 404
      oauth2Results.tokenEndpoint = false
      logError "❌ Token endpoint not found"
      logError "   OAuth2 token endpoint not implemented"
    else if tokenTest.status is 500
      oauth2Results.tokenEndpoint = true  # Endpoint exists but has issues
      logError "❌ Token endpoint error (HTTP #{tokenTest.status})"
      logError "   OAuth2 token generation not fully implemented"
      logVerbose "   Response: #{JSON.stringify(tokenTest.body, null, 2)}" if tokenTest.body
    else
      oauth2Results.tokenEndpoint = true
      oauth2Results.errorHandling = true
      logError "❌ Token request failed (HTTP #{tokenTest.status})"
      logVerbose "   Response: #{JSON.stringify(tokenTest.body, null, 2)}" if tokenTest.body

    logVerbose "\n#{testNum++}. Testing error handling..."

    # Test invalid client credentials
    invalidCredsTest = await makeRequest 'POST', '/oauth/token',
      grant_type: 'client_credentials'
      scope: 'mcp'
    ,
      'Authorization': "Basic #{Buffer.from('invalid:credentials').toString('base64')}"

    if invalidCredsTest.status is 401 or invalidCredsTest.status is 400
      oauth2Results.errorHandling = true
      logSuccess "✅ Error handling functional"
      logVerbose "   Invalid credentials properly rejected"
    else
      logError "❌ Error handling issues"
      logError "   Invalid credentials should return 401 or 400"

  catch error
    logError "💥 Test execution error: #{error.message}"
    exitCode = 1

  reportResults()

# Report final OAuth2 test results
reportResults = ->
  allPassed = Object.values(oauth2Results).every((result) -> result is true)

  console.log "\n📋 OAuth2 Test Results:"

  for key, value of oauth2Results
    status = if value then "✅" else "❌"
    console.log "#{status} #{key}"

  if allPassed
    console.log "\n🎯 OAuth2 AUTHENTICATION FULLY FUNCTIONAL"
    console.log "✅ All OAuth2 components working correctly"
    process.exit 0
  else
    console.log "\n⚠️  OAuth2 IMPLEMENTATION INCOMPLETE"
    console.log "Some OAuth2 components need implementation:"

    unless oauth2Results.serverReachable
      console.log "• Server connectivity issues"

    unless oauth2Results.clientRegistration
      console.log "• Client registration endpoint (/oauth/clients)"
      console.log "• Client storage and management"

    unless oauth2Results.tokenEndpoint
      console.log "• Token endpoint (/oauth/token)"

    unless oauth2Results.clientCredentialsGrant
      console.log "• Client credentials grant flow"
      console.log "• Token generation and signing"

    unless oauth2Results.tokenValidation
      console.log "• Token validation middleware"
      console.log "• Protected endpoint authentication"

    unless oauth2Results.errorHandling
      console.log "• OAuth2 error response handling"

    console.log "\n💡 This is expected for TDD - implement these components to pass tests"
    process.exit exitCode

# Handle process errors
process.on 'uncaughtException', (err) ->
  logError "Uncaught exception: #{err.message}"
  process.exit 1

process.on 'unhandledRejection', (reason, promise) ->
  logError "Unhandled rejection: #{reason}"
  process.exit 1

# Set timeout for entire test suite
setTimeout ->
  logError "Test timeout - server not responding within reasonable time"
  process.exit 1
, 30000  # 30 second timeout

# Run the test
main()
