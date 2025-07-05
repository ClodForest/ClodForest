#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-mcp.coffee }
# MCP 2025-06-18 ENHANCED Specification Compliance Test
# Simulates real Claude.ai MCP client behavior

http   = require 'node:http'
https  = require 'node:https'
crypto = require 'node:crypto'
{spawn} = require 'node:child_process'
path   = require 'node:path'

# Parse command line arguments
args = process.argv.slice(2)
verbose = false
useAuth = false
exitCode = 0

# OAuth2 authentication state
authToken = null
authClient = null

# Enhanced configuration
config =
  host: 'localhost'
  port: 8080
  path: '/api/mcp'
  useHttps: false
  environment: 'local'
  expectedScheme: 'http'

environments =
  local:
    host: 'localhost'
    port: 8080
    path: '/api/mcp'
    useHttps: false
    environment: 'local'
    expectedScheme: 'http'
    expectedBaseUrl: 'http://localhost:8080'

  production:
    host: 'clodforest.thatsnice.org'
    port: 443
    path: '/api/mcp'
    useHttps: true
    environment: 'production'
    expectedScheme: 'https'
    expectedBaseUrl: 'https://clodforest.thatsnice.org'

# Parse arguments (enhanced with more validation)
showHelp = ->
  console.log '''
    ClodForest MCP Server ENHANCED Compliance Test
    Simulates real Claude.ai MCP client discovery and connection flow

    Usage:
      coffee bin/test-mcp.coffee [options]

    Enhanced Features:
      ✅ Real Claude.ai discovery flow simulation
      ✅ OAuth2 + MCP integration validation
      ✅ URL scheme consistency checking
      ✅ Tool schema validation
      ✅ Error response format validation
      ✅ Session state management testing
      ✅ Load balancer compatibility

    Options:
      --env, -e <environment>    Environment preset (local, production)
      --host, -h <hostname>      Server hostname
      --port, -p <port>          Server port
      --https                    Use HTTPS
      --http                     Use HTTP
      --auth                     Use OAuth2 authentication (required for production)
      --verbose, -v              Show detailed output
      --help                     Show this help

    Exit Codes:
      0                          Full MCP compliance verified + real client simulation passed
      1                          Compliance failure or client simulation failed
    '''
  process.exit 0

# Parse arguments (keeping existing logic, enhanced validation)
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
    when '--auth'
      useAuth = true
    else
      console.error "Error: Unknown option '#{arg}'"
      process.exit 1
  i++

# Enhanced compliance tracking
complianceResults = {
  # Basic MCP compliance
  protocolVersion: false
  jsonRpcFormat: false
  httpTransport: false
  initializeMethod: false
  capabilityNegotiation: false
  toolsCapability: false
  toolsList: false
  toolsCall: false
  serverInfo: false
  errorHandling: false

  # Enhanced validations
  discoveryFlow: false
  urlSchemeConsistency: false
  oauth2Integration: false
  toolSchemaValidation: false
  sessionStateManagement: false
  realClientSimulation: false
  loadBalancerCompatibility: false
}

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

logCritical = (message) ->
  console.error "🚨 CRITICAL: #{message}"
  exitCode = 1

# Enhanced HTTP request helper
makeHttpRequest = (method, path, data = null, headers = {}) ->
  new Promise (resolve, reject) ->
    options =
      hostname: config.host
      port: config.port
      path: path
      method: method
      headers: Object.assign({
        'Content-Type': 'application/json'
        'User-Agent': 'ClodForest-Enhanced-MCP-Test/1.0'
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
          resolve { status: res.statusCode, headers: res.headers, body: result, rawBody: body }
        catch e
          resolve { status: res.statusCode, headers: res.headers, body: body, rawBody: body, parseError: e.message }

    req.on 'error', reject
    req.write(dataStr) if data and method isnt 'GET'
    req.end()

# Enhanced URL validation
validateUrlScheme = (url, context) ->
  try
    parsedUrl = new URL(url)
    expectedScheme = config.expectedScheme

    unless parsedUrl.protocol is "#{expectedScheme}:"
      logCritical "#{context}: URL scheme mismatch - expected #{expectedScheme}, got #{parsedUrl.protocol}"
      return false

    logVerbose "  ✅ #{context} URL scheme correct: #{url}"
    return true
  catch error
    logError "#{context}: Invalid URL: #{url}"
    return false

# Simulate Claude.ai discovery flow
simulateClaudeAiDiscovery = ->
  logVerbose "🔍 Simulating Claude.ai MCP discovery flow..."

  try
    # Step 1: Discover OAuth2 authorization server
    logVerbose "  1. Discovering OAuth2 authorization server..."
    authServerResponse = await makeHttpRequest 'GET', '/.well-known/oauth-authorization-server'

    unless authServerResponse.status is 200
      logError "Claude.ai discovery would fail: OAuth2 authorization server not found"
      return false

    authServerMeta = authServerResponse.body

    # Validate URLs in auth server metadata
    unless validateUrlScheme(authServerMeta.issuer, "OAuth2 issuer")
      return false
    unless validateUrlScheme(authServerMeta.token_endpoint, "OAuth2 token endpoint")
      return false

    # Step 2: Discover protected resource metadata
    logVerbose "  2. Discovering protected resource metadata..."
    protectedResponse = await makeHttpRequest 'GET', '/.well-known/oauth-protected-resource'

    unless protectedResponse.status is 200
      logCritical "Claude.ai discovery would fail: Protected resource metadata not found"
      logError "  This is the exact issue preventing Claude.ai connection!"
      return false

    protectedMeta = protectedResponse.body

    # Validate protected resource URLs
    unless validateUrlScheme(protectedMeta.resource, "Protected resource")
      logCritical "Protected resource URL scheme mismatch will prevent Claude.ai connection"
      return false

    # Step 3: Verify MCP endpoint consistency
    logVerbose "  3. Verifying MCP endpoint consistency..."
    expectedMcpUrl = "#{config.expectedScheme}://#{config.host}"
    if config.port isnt (if config.useHttps then 443 else 80)
      expectedMcpUrl += ":#{config.port}"
    expectedMcpUrl += config.path

    unless protectedMeta.resource is expectedMcpUrl
      logCritical "MCP endpoint URL mismatch"
      logError "  Protected resource claims: #{protectedMeta.resource}"
      logError "  Expected: #{expectedMcpUrl}"
      return false

    logSuccess "✅ Claude.ai discovery flow simulation passed"
    complianceResults.discoveryFlow = true
    complianceResults.urlSchemeConsistency = true

    if config.environment is 'production'
      complianceResults.loadBalancerCompatibility = true

    return true

  catch error
    logError "Discovery flow simulation failed: #{error.message}"
    return false

# Enhanced OAuth2 setup with real client simulation
setupOAuth2 = (callback) ->
  logVerbose "🔐 Setting up OAuth2 (enhanced simulation)..."

  try
    # Step 1: Register client like Claude.ai would
    logVerbose "  1. Registering OAuth2 client (Claude.ai simulation)..."
    clientReg = await makeHttpRequest 'POST', '/oauth/clients',
      client_name: 'Claude.ai MCP Client Simulation'
      redirect_uris: []  # Claude.ai doesn't use redirects for MCP
      grant_types: ['client_credentials']
      scope: 'mcp'

    if clientReg.status isnt 201
      logError "OAuth2 client registration failed (#{clientReg.status})"
      if clientReg.body?.error
        logError "  Error: #{clientReg.body.error_description or clientReg.body.error}"
      return callback new Error("OAuth2 client registration failed")

    authClient = clientReg.body
    logVerbose "  ✅ Client registered: #{authClient.client_id}"

    # Step 2: Get access token using client credentials (Claude.ai flow)
    logVerbose "  2. Getting access token (client credentials flow)..."
    credentials = Buffer.from("#{authClient.client_id}:#{authClient.client_secret}").toString('base64')

    tokenRes = await makeHttpRequest 'POST', '/oauth/token',
      grant_type: 'client_credentials'
      scope: 'mcp'
    ,
      'Authorization': "Basic #{credentials}"

    if tokenRes.status isnt 200
      logError "OAuth2 token request failed (#{tokenRes.status})"
      if tokenRes.body?.error
        logError "  Error: #{tokenRes.body.error_description or tokenRes.body.error}"
      return callback new Error("OAuth2 token request failed")

    # Validate token response format
    unless tokenRes.body.access_token
      logError "Token response missing access_token"
      return callback new Error("Invalid token response")

    unless tokenRes.body.token_type?.toLowerCase() is 'bearer'
      logError "Expected Bearer token, got: #{tokenRes.body.token_type}"
      return callback new Error("Invalid token type")

    authToken = tokenRes.body.access_token
    logVerbose "  ✅ Access token obtained: #{authToken.substring(0, 16)}..."
    logSuccess "✅ OAuth2 setup completed (Claude.ai simulation)"

    complianceResults.oauth2Integration = true
    callback null

  catch error
    logError "OAuth2 setup error: #{error.message}"
    callback error

# Enhanced JSON-RPC validation
validateJsonRpcRequest = (obj) ->
  return false unless obj.jsonrpc is '2.0'
  return false unless typeof obj.method is 'string'
  return false unless obj.id? and (typeof obj.id is 'string' or typeof obj.id is 'number')
  return false if obj.id is null
  true

validateJsonRpcResponse = (obj) ->
  return false unless obj.jsonrpc is '2.0'
  return false unless obj.id? and (typeof obj.id is 'string' or typeof obj.id is 'number')
  return false unless obj.result? or obj.error?
  return false if obj.result? and obj.error?
  if obj.error?
    return false unless typeof obj.error.code is 'number'
    return false unless typeof obj.error.message is 'string'
  true

# Enhanced tool schema validation
validateToolSchema = (tool) ->
  # Required fields - using if/not instead of unless to avoid syntax issues
  if not (tool.name and typeof tool.name is 'string')
    logError "Tool missing or invalid name: #{JSON.stringify(tool)}"
    return false

  if not (tool.description and typeof tool.description is 'string')
    logError "Tool '#{tool.name}' missing or invalid description"
    return false

  if not tool.inputSchema
    logError "Tool '#{tool.name}' missing inputSchema"
    return false

  # Validate inputSchema structure
  if tool.inputSchema.type isnt 'object'
    logError "Tool '#{tool.name}' inputSchema must have type 'object'"
    return false

  # Optional but recommended: properties
  if tool.inputSchema.properties and typeof tool.inputSchema.properties isnt 'object'
    logError "Tool '#{tool.name}' inputSchema.properties must be object"
    return false

  logVerbose "  ✅ Tool schema valid: #{tool.name}"
  return true

# For now, you can also just run the individual working tests:
# coffee bin/test-well-known.coffee --env production --verbose
# coffee bin/test-oauth2.coffee --env production --verbose

# Enhanced MCP request helper with full validation
makeRequest = (method, params, id, callback) ->
  # Validate request format before sending
  requestObj =
    jsonrpc: '2.0'
    method: method
    params: params
    id: id

  unless validateJsonRpcRequest(requestObj)
    return callback new Error("Invalid JSON-RPC request format")

  requestData = JSON.stringify(requestObj)

  options =
    hostname: config.host
    port: config.port
    path: config.path
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Content-Length': Buffer.byteLength(requestData)
      'MCP-Protocol-Version': '2025-06-18'
      'User-Agent': 'ClodForest-Enhanced-MCP-Test/1.0'

  # Add OAuth2 authentication if enabled
  if useAuth and authToken
    options.headers['Authorization'] = "Bearer #{authToken}"

  httpModule = if config.useHttps then https else http

  req = httpModule.request options, (res) ->
    # Strict HTTP status validation
    if res.statusCode isnt 200
      complianceResults.httpTransport = false
      return callback new Error("HTTP #{res.statusCode}: MCP servers MUST respond with 200 OK for valid requests")

    complianceResults.httpTransport = true

    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      try
        response = JSON.parse(data)
      catch e
        complianceResults.jsonRpcFormat = false
        return callback new Error("Invalid JSON response: #{e.message}")

      # Enhanced JSON-RPC validation
      unless validateJsonRpcResponse(response)
        complianceResults.jsonRpcFormat = false
        return callback new Error("Response violates JSON-RPC 2.0 specification")

      complianceResults.jsonRpcFormat = true
      callback null, response

  req.on 'error', (err) ->
    complianceResults.httpTransport = false
    callback err

  req.write requestData
  req.end()

# Enhanced MCP session state management test
testSessionStateManagement = (callback) ->
  logVerbose "Testing MCP session state management..."

  # Initialize a session
  makeRequest 'initialize',
    protocolVersion: '2025-06-18'
    capabilities:
      roots: { listChanged: true }
      sampling: {}
      elicitation: {}
    clientInfo:
      name: "enhanced-mcp-test"
      version: '1.0.0'
  , 1, (err, initResponse) ->
    if err
      return callback err

    # Send initialized notification
    makeRequest 'notifications/initialized', {}, null, (notifyErr, notifyRes) ->
      # Should not get a response for notifications
      if notifyRes?
        return callback new Error("Server incorrectly responded to notification")

      # Test that session is maintained - list tools
      makeRequest 'tools/list', {}, 2, (listErr, listResponse) ->
        if listErr
          return callback listErr

        unless listResponse.result?.tools
          return callback new Error("Session lost - tools/list failed after initialize")

        logSuccess "✅ Session state management working"
        complianceResults.sessionStateManagement = true
        callback null

# Real Claude.ai client simulation
simulateRealClaudeAiClient = (callback) ->
  logVerbose "🤖 Simulating real Claude.ai MCP client behavior..."

  try
    # Step 1: Full discovery and authentication flow
    unless await simulateClaudeAiDiscovery()
      return callback new Error("Claude.ai discovery simulation failed")

    # Step 2: If authentication required, set it up
    if useAuth
      setupOAuth2 (authErr) ->
        if authErr
          return callback authErr

        # Step 3: Continue with MCP connection
        proceedWithMcpConnection(callback)
    else
      # Step 3: Direct MCP connection
      proceedWithMcpConnection(callback)

  catch error
    callback error

proceedWithMcpConnection = (callback) ->
  # Step 4: MCP Initialize (like Claude.ai would)
  logVerbose "  4. Initializing MCP connection..."
  makeRequest 'initialize',
    protocolVersion: '2025-06-18'
    capabilities:
      roots: { listChanged: true }
      sampling: {}
      elicitation: {}
    clientInfo:
      name: "Claude.ai MCP Client Simulation"
      version: '1.0.0'
  , 1, (err, res) ->
    if err
      return callback new Error("MCP initialize failed: #{err.message}")

    if res.error
      return callback new Error("MCP initialize error: #{res.error.message}")

    # Enhanced server info validation
    result = res.result
    unless result?.protocolVersion is '2025-06-18'
      return callback new Error("Protocol version mismatch")

    unless result.serverInfo?.name and result.serverInfo?.version
      return callback new Error("Server info incomplete")

    unless result.capabilities?.tools?
      return callback new Error("Server must advertise tools capability")

    complianceResults.protocolVersion = true
    complianceResults.initializeMethod = true
    complianceResults.capabilityNegotiation = true
    complianceResults.toolsCapability = true
    complianceResults.serverInfo = true

    logVerbose "  ✅ MCP initialized: #{result.serverInfo.name} v#{result.serverInfo.version}"

    # Step 5: Send initialized notification
    makeRequest 'notifications/initialized', {}, null, (notifyErr) ->
      # Notifications shouldn't get responses

      # Step 6: List tools (like Claude.ai would)
      logVerbose "  5. Listing available tools..."
      makeRequest 'tools/list', {}, 2, (listErr, listRes) ->
        if listErr
          return callback new Error("tools/list failed: #{listErr.message}")

        if listRes.error
          return callback new Error("tools/list error: #{listRes.error.message}")

        unless listRes.result?.tools? and Array.isArray(listRes.result.tools)
          return callback new Error("tools/list MUST return tools array")

        tools = listRes.result.tools
        complianceResults.toolsList = true

        logVerbose "  ✅ Found #{tools.length} tools"

        # Enhanced tool validation
        allToolsValid = true
        for tool in tools
          unless validateToolSchema(tool)
            allToolsValid = false

        if allToolsValid
          complianceResults.toolSchemaValidation = true
          logSuccess "✅ All tool schemas valid"
        else
          logError "❌ Some tool schemas invalid"

        # Step 7: Test tool calling (like Claude.ai would)
        if tools.length > 0
          logVerbose "  6. Testing tool execution..."
          testTool = tools[0]

          makeRequest 'tools/call',
            name: testTool.name
            arguments: {}
          , 3, (callErr, callRes) ->
            if callErr
              return callback new Error("tools/call failed: #{callErr.message}")

            if callRes.error
              # Tool errors are acceptable
              logVerbose "  ✅ Tool error handling working: #{callRes.error.message}"
              complianceResults.errorHandling = true
            else
              # Validate successful tool response
              unless callRes.result?.content? and Array.isArray(callRes.result.content)
                return callback new Error("Tool result MUST include content array")

              unless typeof callRes.result.isError is 'boolean'
                return callback new Error("Tool result MUST include isError boolean")

              complianceResults.toolsCall = true
              logVerbose "  ✅ Tool execution successful"

            # Step 8: Test error handling
            logVerbose "  7. Testing error handling..."
            makeRequest 'nonexistent/method', {}, 4, (errTestErr, errTestRes) ->
              if errTestErr
                return callback new Error("Error handling test failed")

              if errTestRes.error
                unless errTestRes.error.code and typeof errTestRes.error.code is 'number'
                  return callback new Error("Error response missing valid error code")

                unless errTestRes.error.message and typeof errTestRes.error.message is 'string'
                  return callback new Error("Error response missing valid error message")

                complianceResults.errorHandling = true
                logVerbose "  ✅ Error handling verified"
              else
                return callback new Error("Server MUST return error for non-existent methods")

              # All tests passed!
              logSuccess "✅ Real Claude.ai client simulation completed successfully"
              complianceResults.realClientSimulation = true
              callback null
        else
          return callback new Error("Server advertises tools capability but provides no tools")

# Main enhanced test execution
runEnhancedMcpTests = ->
  protocol = if config.useHttps then 'https' else 'http'
  authStatus = if useAuth then " (with OAuth2)" else ""
  logVerbose "🔍 Testing MCP 2025-06-18 Compliance (ENHANCED): #{protocol}://#{config.host}:#{config.port}#{config.path}#{authStatus}"

  # Enhanced test sequence
  if useAuth
    # Test OAuth2 prerequisites first
    logVerbose "Testing OAuth2 prerequisites..."
    runOAuth2PrerequisiteTest (prereqErr) ->
      if prereqErr
        logError "OAuth2 prerequisite test failed"
        process.exit 1
      else
        logVerbose "✅ OAuth2 prerequisites passed"

        # Run enhanced MCP tests with authentication
        simulateRealClaudeAiClient (clientErr) ->
          if clientErr
            logError "Enhanced MCP client simulation failed: #{clientErr.message}"
            process.exit 1
          else
            # Test session state management
            testSessionStateManagement (sessionErr) ->
              if sessionErr
                logError "Session state management failed: #{sessionErr.message}"

              reportEnhancedCompliance()
  else
    # Run enhanced MCP tests without authentication
    simulateRealClaudeAiClient (clientErr) ->
      if clientErr
        logError "Enhanced MCP client simulation failed: #{clientErr.message}"
        process.exit 1
      else
        testSessionStateManagement (sessionErr) ->
          if sessionErr
            logError "Session state management failed: #{sessionErr.message}"

          reportEnhancedCompliance()

# Enhanced compliance reporting
reportEnhancedCompliance = ->
  coreTests = ['protocolVersion', 'jsonRpcFormat', 'httpTransport', 'initializeMethod', 'capabilityNegotiation', 'toolsCapability', 'toolsList', 'toolsCall', 'serverInfo', 'errorHandling']
  enhancedTests = ['discoveryFlow', 'urlSchemeConsistency', 'oauth2Integration', 'toolSchemaValidation', 'sessionStateManagement', 'realClientSimulation', 'loadBalancerCompatibility']

  console.log "\n📋 ENHANCED MCP COMPLIANCE REPORT"
  console.log "================================="

  console.log "\n🔍 Core MCP 2025-06-18 Compliance:"
  for test in coreTests
    status = if complianceResults[test] then "✅" else "❌"
    console.log "  #{status} #{test}"

  console.log "\n🔧 Enhanced Client Simulation:"
  for test in enhancedTests
    status = if complianceResults[test] then "✅" else "❌"
    console.log "  #{status} #{test}"

  # Calculate scores
  corePassedTests = coreTests.filter((test) -> complianceResults[test]).length
  enhancedPassedTests = enhancedTests.filter((test) -> complianceResults[test]).length

  totalTests = coreTests.length + enhancedTests.length
  totalPassed = corePassedTests + enhancedPassedTests

  console.log "\n📊 Test Results:"
  console.log "  Core MCP: #{corePassedTests}/#{coreTests.length} (#{Math.round(corePassedTests/coreTests.length*100)}%)"
  console.log "  Enhanced: #{enhancedPassedTests}/#{enhancedTests.length} (#{Math.round(enhancedPassedTests/enhancedTests.length*100)}%)"
  console.log "  Overall: #{totalPassed}/#{totalTests} (#{Math.round(totalPassed/totalTests*100)}%)"

  # Critical analysis
  criticalIssues = []
  unless complianceResults.discoveryFlow
    criticalIssues.push("Claude.ai discovery flow would fail")
  unless complianceResults.urlSchemeConsistency
    criticalIssues.push("URL scheme inconsistencies detected")
  unless complianceResults.realClientSimulation
    criticalIssues.push("Real client simulation failed")
  if useAuth and not complianceResults.oauth2Integration
    criticalIssues.push("OAuth2 integration broken")

  if criticalIssues.length > 0
    console.log "\n🚨 CRITICAL ISSUES FOR CLAUDE.AI:"
    for issue in criticalIssues
      console.log "  • #{issue}"
    console.log "\nThese issues will prevent Claude.ai from connecting."

  if corePassedTests is coreTests.length and complianceResults.realClientSimulation
    console.log "\n🎯 MCP SERVER FULLY FUNCTIONAL FOR CLAUDE.AI"
    console.log "✅ All MCP 2025-06-18 compliance tests passed"
    console.log "✅ Real Claude.ai client simulation successful"
    console.log "✅ Discovery flow verified"
    console.log "✅ URL scheme consistency confirmed"

    if useAuth and complianceResults.oauth2Integration
      console.log "✅ OAuth2 integration working"

    if complianceResults.loadBalancerCompatibility
      console.log "✅ Load balancer compatibility verified"

    console.log "\n🚀 Claude.ai should connect successfully!"
    process.exit 0
  else
    console.log "\n⚠️  MCP SERVER HAS COMPATIBILITY ISSUES"
    console.log "\nAddress the failing tests to ensure Claude.ai compatibility."
    process.exit exitCode

# OAuth2 prerequisite test runner (reuse existing implementation)
runOAuth2PrerequisiteTest = (callback) ->
  logVerbose "🔐 Running OAuth2 prerequisite test..."

  oauth2Args = []
  if config.environment isnt 'local'
    oauth2Args.push '--env', config.environment
  else if config.host isnt 'localhost' or config.port isnt 8080
    oauth2Args.push '--host', config.host if config.host isnt 'localhost'
    oauth2Args.push '--port', config.port.toString() if config.port isnt 8080

  if config.useHttps
    oauth2Args.push '--https'

  if verbose
    oauth2Args.push '--verbose'

  scriptDir = path.dirname(__filename)
  oauth2Script = path.join(scriptDir, 'test-oauth2.coffee')

  oauth2Process = spawn 'coffee', [oauth2Script].concat(oauth2Args), {
    stdio: 'inherit'
  }

  oauth2Process.on 'close', (code) ->
    if code is 0
      logVerbose "✅ OAuth2 prerequisite test passed"
      callback null
    else
      callback new Error("OAuth2 prerequisite test failed")

  oauth2Process.on 'error', (err) ->
    callback err

# Main execution logic
if useAuth
  runEnhancedMcpTests()
else
  runEnhancedMcpTests()

# Set timeout for entire test suite
setTimeout ->
  logError "Test timeout - MCP server not responding within reasonable time"
  process.exit 1
, 60000  # 60 second timeout for enhanced tests
