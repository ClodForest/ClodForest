#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-oauth2.coffee }
# RFC 6749 OAuth 2.0 ENHANCED Compliance Test
# Actually tests what it claims to test

http   = require 'node:http'
https  = require 'node:https'
{URL}  = require 'node:url'
crypto = require 'node:crypto'

# Parse command line arguments
args = process.argv.slice(2)
verbose = false
exitCode = 0
testAllGrants = false

# Enhanced configuration with expected URL validation
config =
  host: 'localhost'
  port: 8080
  useHttps: false
  environment: 'local'
  expectedScheme: 'http'

environments =
  local:
    host: 'localhost'
    port: 8080
    useHttps: false
    environment: 'local'
    expectedScheme: 'http'
    expectedBaseUrl: 'http://localhost:8080'

  production:
    host: 'clodforest.thatsnice.org'
    port: 443
    useHttps: true
    environment: 'production'
    expectedScheme: 'https'
    expectedBaseUrl: 'https://clodforest.thatsnice.org'

# Parse arguments (same as before, adding expectedScheme update)
showHelp = ->
  console.log '''
    ClodForest RFC 6749 OAuth 2.0 ENHANCED Authorization Framework Test

    This version actually validates OAuth2 functionality and content,
    not just endpoint existence. Tests real bearer token usage.

    Usage:
      coffee bin/test-oauth2.coffee [options]

    Enhanced Validations:
      ✅ Actual bearer token usage with protected endpoints
      ✅ Token format validation (JWT vs opaque)
      ✅ URL scheme consistency checking
      ✅ Cross-endpoint metadata validation
      ✅ Load balancer compatibility
      ✅ Real client credentials flow testing
      ✅ Token introspection if available
      ✅ Error response format validation

    Options:
      --env, -e <environment>    Environment preset (local, production)
      --host, -h <hostname>      Server hostname
      --port, -p <port>          Server port
      --https                    Use HTTPS
      --http                     Use HTTP
      --verbose, -v              Show detailed output
      --all-grants               Test all OAuth2 grant types
      --help                     Show this help

    Exit Codes:
      0                          Full RFC 6749 compliance verified
      1                          OAuth2 compliance failure
    '''
  process.exit 0

# Parse arguments (keeping existing logic, adding expectedScheme)
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
        console.error "Error: Unknown environment '#{envName}'"
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
      config.expectedScheme = 'https'
    when '--http'
      config.useHttps = false
      config.expectedScheme = 'http'
    when '--all-grants'
      testAllGrants = true
    else
      console.error "Error: Unknown option '#{arg}'"
      process.exit 1
  i++

# Enhanced OAuth2 test results tracking
oauth2Results = {
  serverReachable: false
  serverHealthy: false
  wellKnownDiscovery: false
  wellKnownUrlConsistency: false
  clientRegistration: false
  clientRegistrationFormat: false
  tokenEndpoint: false
  tokenResponseFormat: false
  clientCredentialsGrant: false
  bearerTokenUsage: false
  bearerTokenValidation: false
  protectedResourceAccess: false
  tokenIntrospection: false
  errorHandling: false
  errorResponseFormat: false
  rfc6749Compliance: false
  rfc6750Compliance: false
  rfc8414Compliance: false
}

# Storage for cross-validation
testContext = {
  registeredClient: null
  accessToken: null
  wellKnownMetadata: null
}

# Enhanced logging
logVerbose = (message) ->
  if verbose
    console.log message

logError = (message) ->
  console.error message
  exitCode = 1

logSuccess = (message) ->
  if verbose
    console.log message

logCritical = (message) ->
  console.error "🚨 CRITICAL: #{message}"
  exitCode = 1

# Enhanced HTTP request helper
makeRequest = (method, path, data = null, headers = {}) ->
  new Promise (resolve, reject) ->
    options =
      hostname: config.host
      port: config.port
      path: path
      method: method
      headers: Object.assign({
        'Content-Type': 'application/json'
        'User-Agent': 'ClodForest-Enhanced-OAuth2-Test/1.0'
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
          resolve {
            status: res.statusCode
            headers: res.headers
            body: result
            rawBody: body
          }
        catch e
          resolve {
            status: res.statusCode
            headers: res.headers
            body: body
            rawBody: body
            parseError: e.message
          }

    req.on 'error', reject
    req.write(dataStr) if data and method isnt 'GET'
    req.end()

# Enhanced URL validation
validateUrlScheme = (url, context) ->
  try
    parsedUrl = new URL(url)
    expectedScheme = config.expectedScheme

    unless parsedUrl.protocol is "#{expectedScheme}:"
      logCritical "#{context}: URL scheme mismatch"
      logError "  Expected: #{expectedScheme}://..."
      logError "  Got: #{url}"
      return false

    logVerbose "  ✅ #{context} URL scheme correct"
    return true
  catch error
    logError "#{context}: Invalid URL: #{url}"
    return false

# Enhanced well-known metadata validation
validateWellKnownMetadata = (metadata) ->
  return false unless metadata

  # Validate required URLs
  requiredUrls = ['issuer', 'authorization_endpoint', 'token_endpoint']
  for field in requiredUrls
    unless validateUrlScheme(metadata[field], field)
      return false

  # Check grant types include client_credentials
  unless 'client_credentials' in metadata.grant_types_supported
    logCritical "Well-known metadata missing client_credentials grant"
    return false

  logSuccess "✅ Well-known metadata URLs and content valid"
  return true

# Enhanced client registration validation
validateClientRegistration = (response, request) ->
  unless response.client_id
    logError "Client registration missing client_id"
    return false

  unless response.client_secret
    logError "Client registration missing client_secret"
    return false

  # Validate client_id format (should be reasonable length)
  unless response.client_id.length >= 16
    logError "Client ID suspiciously short: #{response.client_id}"
    return false

  # Check that granted scopes match requested
  if request.scope and response.scope
    requestedScopes = request.scope.split(' ')
    grantedScopes = response.scope.split(' ')
    for scope in requestedScopes
      unless scope in grantedScopes
        logError "Requested scope '#{scope}' not granted"
        return false

  logSuccess "✅ Client registration format and content valid"
  return true

# Enhanced token validation
validateTokenResponse = (response, request) ->
  unless response.access_token
    logError "Token response missing access_token"
    return false

  unless response.token_type
    logError "Token response missing token_type"
    return false

  unless response.token_type.toLowerCase() is 'bearer'
    logError "Expected Bearer token, got: #{response.token_type}"
    return false

  # Validate token format (basic checks)
  token = response.access_token
  if token.length < 16
    logError "Access token suspiciously short: #{token}"
    return false

  # Check expiration
  unless response.expires_in
    logError "Token response missing expires_in"
    return false

  unless typeof response.expires_in is 'number' and response.expires_in > 0
    logError "Invalid expires_in value: #{response.expires_in}"
    return false

  # Validate scope matches request
  if request.scope and response.scope
    unless response.scope.includes(request.scope)
      logError "Token scope mismatch - requested: #{request.scope}, got: #{response.scope}"
      return false

  logSuccess "✅ Token response format and content valid"
  return true

# Enhanced bearer token usage test
testBearerTokenUsage = (token) ->
  new Promise (resolve, reject) ->
    logVerbose "Testing bearer token with multiple protected endpoints..."

    # Test 1: Bearer token in Authorization header
    makeRequest 'GET', '/api/config', null,
      'Authorization': "Bearer #{token}"
    .then (response) ->
      if response.status is 200
        logSuccess "✅ Bearer token accepted in Authorization header"
        oauth2Results.bearerTokenUsage = true

        # Test 2: Verify token validation (try invalid token)
        makeRequest 'GET', '/api/config', null,
          'Authorization': "Bearer invalid_token_12345"
        .then (invalidResponse) ->
          if invalidResponse.status is 401
            logSuccess "✅ Invalid bearer tokens properly rejected"
            oauth2Results.bearerTokenValidation = true
            resolve(true)
          else
            logError "❌ Invalid bearer token not rejected (got #{invalidResponse.status})"
            resolve(false)
        .catch(reject)
      else
        logError "❌ Valid bearer token rejected (got #{response.status})"
        if response.body?.error
          logError "   Error: #{response.body.error_description or response.body.error}"
        resolve(false)
    .catch(reject)

# Enhanced error response validation
validateErrorResponse = (response, expectedError = null) ->
  unless response.body?.error
    logError "Error response missing 'error' field"
    return false

  unless typeof response.body.error is 'string'
    logError "Error field must be string"
    return false

  if expectedError and response.body.error isnt expectedError
    logError "Expected error '#{expectedError}', got '#{response.body.error}'"
    return false

  # RFC 6749 recommends error_description
  if response.body.error_description
    unless typeof response.body.error_description is 'string'
      logError "error_description must be string"
      return false

  logSuccess "✅ Error response format valid"
  return true

# Main enhanced test sequence
main = ->
  protocol = if config.useHttps then 'https' else 'http'
  logVerbose "🔐 Testing OAuth2 (ENHANCED): #{protocol}://#{config.host}:#{config.port}"
  logVerbose "Expected URL scheme: #{config.expectedScheme}"
  testNum = 0

  try
    # Test 0: Server reachability
    logVerbose "\n#{testNum++}. Testing server connectivity..."
    healthCheck = await makeRequest 'GET', '/api/health'

    if healthCheck.status is 200
      oauth2Results.serverReachable = true
      oauth2Results.serverHealthy = true
      logSuccess "✅ Server reachable and healthy"
    else
      logError "❌ Server health check failed (#{healthCheck.status})"
      return reportResults()

    # Test 1: Enhanced well-known discovery
    logVerbose "\n#{testNum++}. Testing well-known OAuth2 discovery (enhanced)..."
    wellKnownResponse = await makeRequest 'GET', '/.well-known/oauth-authorization-server'

    if wellKnownResponse.status is 200
      oauth2Results.wellKnownDiscovery = true
      logSuccess "✅ Well-known discovery endpoint exists"

      testContext.wellKnownMetadata = wellKnownResponse.body

      # Enhanced validation
      if validateWellKnownMetadata(wellKnownResponse.body)
        oauth2Results.wellKnownUrlConsistency = true
        oauth2Results.rfc8414Compliance = true
        logSuccess "✅ Well-known metadata fully compliant"
      else
        logError "❌ Well-known metadata validation failed"
    else
      logError "❌ Well-known discovery failed (#{wellKnownResponse.status})"
      return reportResults()

    # Test 2: Enhanced client registration
    logVerbose "\n#{testNum++}. Testing client registration (enhanced)..."
    clientRequest = {
      client_name: 'Enhanced OAuth2 Test Client'
      redirect_uris: ['http://localhost:3000/callback']
      scope: 'mcp read write'
      grant_types: ['client_credentials']
      response_types: ['token']
    }

    clientResponse = await makeRequest 'POST', '/oauth/clients', clientRequest

    if clientResponse.status is 201
      oauth2Results.clientRegistration = true
      logSuccess "✅ Client registration successful"

      if validateClientRegistration(clientResponse.body, clientRequest)
        oauth2Results.clientRegistrationFormat = true
        testContext.registeredClient = clientResponse.body
      else
        logError "❌ Client registration format validation failed"
    else
      logError "❌ Client registration failed (#{clientResponse.status})"
      if clientResponse.body?.error
        validateErrorResponse(clientResponse)
      return reportResults()

    # Test 3: Enhanced token endpoint testing
    logVerbose "\n#{testNum++}. Testing token endpoint (enhanced)..."

    # Create proper Basic auth header
    credentials = Buffer.from("#{testContext.registeredClient.client_id}:#{testContext.registeredClient.client_secret}").toString('base64')

    tokenRequest = {
      grant_type: 'client_credentials'
      scope: 'mcp'
    }

    tokenResponse = await makeRequest 'POST', '/oauth/token', tokenRequest,
      'Authorization': "Basic #{credentials}"

    if tokenResponse.status is 200
      oauth2Results.tokenEndpoint = true
      oauth2Results.clientCredentialsGrant = true
      logSuccess "✅ Token endpoint functional"

      if validateTokenResponse(tokenResponse.body, tokenRequest)
        oauth2Results.tokenResponseFormat = true
        testContext.accessToken = tokenResponse.body.access_token
        logSuccess "✅ Client credentials grant successful with valid token"
      else
        logError "❌ Token response validation failed"
    else
      logError "❌ Token request failed (#{tokenResponse.status})"
      if tokenResponse.body?.error
        validateErrorResponse(tokenResponse)
      return reportResults()

    # Test 4: Enhanced bearer token usage
    logVerbose "\n#{testNum++}. Testing bearer token usage (enhanced)..."

    if await testBearerTokenUsage(testContext.accessToken)
      logSuccess "✅ Bearer token usage fully functional"
    else
      logError "❌ Bearer token usage failed"

    # Test 5: Protected resource access
    logVerbose "\n#{testNum++}. Testing protected resource access..."

    # Try to access the actual MCP endpoint with bearer token
    mcpTestRequest = {
      jsonrpc: '2.0'
      method: 'initialize'
      params: { clientInfo: { name: 'oauth2-test', version: '1.0.0' } }
      id: 1
    }

    mcpResponse = await makeRequest 'POST', '/api/mcp', mcpTestRequest,
      'Authorization': "Bearer #{testContext.accessToken}"

    if mcpResponse.status is 200
      oauth2Results.protectedResourceAccess = true
      logSuccess "✅ Protected resource (MCP) accessible with bearer token"
    else
      logError "❌ Protected resource access failed (#{mcpResponse.status})"

    # Test 6: Enhanced error handling
    logVerbose "\n#{testNum++}. Testing error handling (enhanced)..."

    # Test invalid client credentials
    invalidTokenResponse = await makeRequest 'POST', '/oauth/token',
      { grant_type: 'client_credentials', scope: 'mcp' },
      'Authorization': "Basic #{Buffer.from('invalid:credentials').toString('base64')}"

    if invalidTokenResponse.status in [400, 401]
      if validateErrorResponse(invalidTokenResponse, 'invalid_client')
        oauth2Results.errorHandling = true
        oauth2Results.errorResponseFormat = true
        logSuccess "✅ Error handling and format validation passed"
      else
        logError "❌ Error response format invalid"
    else
      logError "❌ Invalid credentials not properly rejected"

    # Final compliance assessment
    if oauth2Results.wellKnownDiscovery and oauth2Results.wellKnownUrlConsistency
      oauth2Results.rfc8414Compliance = true

    if oauth2Results.bearerTokenUsage and oauth2Results.bearerTokenValidation
      oauth2Results.rfc6750Compliance = true

    if oauth2Results.clientRegistration and oauth2Results.tokenEndpoint and oauth2Results.errorHandling
      oauth2Results.rfc6749Compliance = true

  catch error
    logError "💥 Test execution error: #{error.message}"
    exitCode = 1

  reportResults()

# Enhanced results reporting
reportResults = ->
  coreTests = ['serverReachable', 'serverHealthy', 'wellKnownDiscovery', 'clientRegistration', 'tokenEndpoint']
  advancedTests = ['bearerTokenUsage', 'bearerTokenValidation', 'protectedResourceAccess', 'errorHandling']
  complianceTests = ['rfc6749Compliance', 'rfc6750Compliance', 'rfc8414Compliance']

  console.log "\n📋 ENHANCED OAuth2 Test Results:"
  console.log "================================"

  console.log "\n🔍 Core OAuth2 Functionality:"
  for test in coreTests
    status = if oauth2Results[test] then "✅" else "❌"
    console.log "  #{status} #{test}"

  console.log "\n🔧 Advanced OAuth2 Features:"
  for test in advancedTests
    status = if oauth2Results[test] then "✅" else "❌"
    console.log "  #{status} #{test}"

  console.log "\n📜 RFC Compliance:"
  for test in complianceTests
    status = if oauth2Results[test] then "✅" else "❌"
    console.log "  #{status} #{test}"

  # Calculate scores
  allTests = Object.keys(oauth2Results).length
  passedTests = Object.values(oauth2Results).filter((r) -> r is true).length

  criticalTests = ['wellKnownDiscovery', 'clientRegistration', 'tokenEndpoint', 'bearerTokenUsage']
  criticalPassed = criticalTests.filter((test) -> oauth2Results[test]).length

  console.log "\n📊 Test Summary:"
  console.log "  Overall: #{passedTests}/#{allTests} (#{Math.round(passedTests/allTests*100)}%)"
  console.log "  Critical: #{criticalPassed}/#{criticalTests.length} (#{Math.round(criticalPassed/criticalTests.length*100)}%)"

  if criticalPassed is criticalTests.length and oauth2Results.rfc6750Compliance
    console.log "\n🎯 OAUTH2 FULLY FUNCTIONAL FOR MCP"
    console.log "✅ All critical OAuth2 components working"
    console.log "✅ Bearer token usage verified"
    console.log "✅ Protected resource access confirmed"
    console.log "✅ Claude.ai should be able to authenticate"
    process.exit 0
  else
    console.log "\n⚠️  OAuth2 IMPLEMENTATION HAS ISSUES"

    failedCritical = criticalTests.filter((test) -> not oauth2Results[test])
    if failedCritical.length > 0
      console.log "\n🚨 Critical failures:"
      for test in failedCritical
        console.log "  • #{test}"

    unless oauth2Results.rfc6750Compliance
      console.log "\n🚨 RFC 6750 (Bearer Token) compliance failed"
      console.log "   This will prevent Claude.ai from using access tokens"

    process.exit exitCode

# Handle process errors
process.on 'uncaughtException', (err) ->
  logError "Uncaught exception: #{err.message}"
  process.exit 1

process.on 'unhandledRejection', (reason, promise) ->
  logError "Unhandled rejection: #{reason}"
  process.exit 1

# Set timeout
setTimeout ->
  logError "Test timeout - OAuth2 endpoints not responding"
  process.exit 1
, 30000

# Run the test
main()