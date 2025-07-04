#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-mcp.coffee }
# MCP 2025-06-18 Specification Compliance Test Script
# Tests comprehensive MCP compliance according to JSON-RPC 2.0 and HTTP transport requirements
# Only reports success on true compliance, no fallbacks

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

# Default configuration (local development)
config =
  host: 'localhost'
  port: 8080
  path: '/api/mcp'
  useHttps: false
  environment: 'local'

# Environment presets
environments =
  local:
    host: 'localhost'
    port: 8080
    path: '/api/mcp'
    useHttps: false
    environment: 'local'
  
  production:
    host: 'clodforest.thatsnice.org'
    port: 443
    path: '/api/mcp'
    useHttps: true
    environment: 'production'

# Parse arguments
showHelp = ->
  console.log '''
    ClodForest MCP Server Compliance Test Script
    
    Usage:
      coffee bin/test-mcp.coffee [options]
    
    Options:
      --env, -e <environment>    Environment preset (local, production)
      --host, -h <hostname>      Server hostname
      --port, -p <port>          Server port
      --https                    Use HTTPS
      --http                     Use HTTP
      --auth                     Use OAuth2 authentication
      --verbose, -v              Show detailed output on success
      --help                     Show this help
    
    Environment Presets:
      local                      http://localhost:8080/api/mcp (default)
      production                 https://clodforest.thatsnice.org:443/api/mcp
    
    Exit Codes:
      0                          Full MCP compliance verified
      1                          Compliance failure or error
    
    Examples:
      coffee bin/test-mcp.coffee                           # Test local (silent unless error)
      coffee bin/test-mcp.coffee --verbose                 # Test local with details
      coffee bin/test-mcp.coffee --auth                    # Test with OAuth2 authentication
      coffee bin/test-mcp.coffee --env production -v       # Test production with details
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
    
    when '--auth'
      useAuth = true
    
    else
      console.error "Error: Unknown option '#{arg}'"
      console.error "Use --help for usage information"
      process.exit 1
  
  i++

# Compliance tracking
complianceResults = {
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

# OAuth2 helper functions
makeHttpRequest = (method, path, data = null, headers = {}) ->
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

# OAuth2 authentication setup
setupOAuth2 = (callback) ->
  logVerbose "🔐 Setting up OAuth2 authentication..."
  
  try
    # Step 1: Register OAuth2 client
    logVerbose "  1. Registering OAuth2 client..."
    clientReg = await makeHttpRequest 'POST', '/oauth/clients',
      name: 'MCP Compliance Test Client'
      redirect_uris: ['http://localhost:3000/callback']
      scope: 'mcp read write'
    
    if clientReg.status isnt 201
      if clientReg.status is 404
        logError "❌ OAuth2 client registration endpoint not found"
        logError "   OAuth2 infrastructure not implemented"
      else if clientReg.status is 500
        logError "❌ OAuth2 client registration failed - server error"
        logError "   OAuth2 infrastructure incomplete"
      else
        logError "❌ OAuth2 client registration failed (HTTP #{clientReg.status})"
      
      logError "   Run without --auth flag to test MCP without authentication"
      return callback new Error("OAuth2 setup failed")
    
    authClient = clientReg.body
    logVerbose "  ✅ Client registered: #{authClient.client_id}"
    
    # Step 2: Get access token via client credentials grant
    logVerbose "  2. Getting access token..."
    credentials = Buffer.from("#{authClient.client_id}:#{authClient.client_secret}").toString('base64')
    
    tokenRes = await makeHttpRequest 'POST', '/oauth/token',
      grant_type: 'client_credentials'
      scope: 'mcp'
    ,
      'Authorization': "Basic #{credentials}"
    
    if tokenRes.status isnt 200
      if tokenRes.status is 404
        logError "❌ OAuth2 token endpoint not found"
        logError "   OAuth2 token infrastructure not implemented"
      else if tokenRes.status is 500
        logError "❌ OAuth2 token generation failed - server error"
        logError "   OAuth2 token infrastructure incomplete"
      else
        logError "❌ OAuth2 token request failed (HTTP #{tokenRes.status})"
      
      return callback new Error("OAuth2 token setup failed")
    
    authToken = tokenRes.body.access_token
    logVerbose "  ✅ Access token obtained: #{authToken.substring(0, 16)}..."
    logVerbose "🔐 OAuth2 authentication ready"
    
    callback null
  
  catch error
    logError "💥 OAuth2 setup error: #{error.message}"
    callback error

# Validate JSON-RPC 2.0 message format
validateJsonRpcRequest = (obj) ->
  return false unless obj.jsonrpc is '2.0'
  return false unless typeof obj.method is 'string'
  return false unless obj.id? and (typeof obj.id is 'string' or typeof obj.id is 'number')
  return false if obj.id is null  # MCP explicitly forbids null IDs
  true

validateJsonRpcResponse = (obj) ->
  return false unless obj.jsonrpc is '2.0'
  return false unless obj.id? and (typeof obj.id is 'string' or typeof obj.id is 'number')
  return false unless obj.result? or obj.error?
  return false if obj.result? and obj.error?  # Cannot have both
  if obj.error?
    return false unless typeof obj.error.code is 'number'
    return false unless typeof obj.error.message is 'string'
  true

# Helper to make JSON-RPC request with strict validation
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
      'MCP-Protocol-Version': '2025-06-18'  # Required for HTTP transport
  
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
      
      # Validate JSON-RPC response format
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

# Main test execution function
runMcpTests = ->
  # Test sequence with strict compliance validation
  protocol = if config.useHttps then 'https' else 'http'
  authStatus = if useAuth then " (with OAuth2)" else ""
  logVerbose "🔍 Testing MCP 2025-06-18 Compliance: #{protocol}://#{config.host}:#{config.port}#{config.path}#{authStatus}"

  # Test 1: Initialize with strict protocol validation
  makeRequest 'initialize', 
    protocolVersion: '2025-06-18'
    capabilities:
      roots: { listChanged: true }
      sampling: {}
      elicitation: {}
    clientInfo:
      name: "mcp-compliance-test"
      version: '1.0.0'
  , 1, (err, res) ->
    if err
      logError "Initialize failed: #{err.message}"
      process.exit exitCode
    
    if res.error
      logError "Initialize error: #{res.error.message} (code: #{res.error.code})"
      complianceResults.errorHandling = true  # At least error format is correct
      process.exit exitCode
    
    # Validate initialize response structure
    result = res.result
    unless result?
      logError "Initialize response missing result field"
      process.exit exitCode
    
    # Protocol version validation
    unless result.protocolVersion is '2025-06-18'
      logError "Protocol version mismatch. Expected: 2025-06-18, Got: #{result.protocolVersion}"
      process.exit exitCode
    
    complianceResults.protocolVersion = true
    complianceResults.initializeMethod = true
    logVerbose "✅ Protocol version: #{result.protocolVersion}"
    
    # Server info validation
    unless result.serverInfo?.name and result.serverInfo?.version
      logError "Server info incomplete - missing required name or version"
      process.exit exitCode
    
    complianceResults.serverInfo = true
    logVerbose "✅ Server: #{result.serverInfo.name} v#{result.serverInfo.version}"
    
    # Capability validation - MUST have capabilities object
    unless result.capabilities?
      logError "Server MUST advertise capabilities in initialize response"
      process.exit exitCode
    
    complianceResults.capabilityNegotiation = true
    
    # Tools capability validation - MUST be present for tool servers
    unless result.capabilities.tools?
      logError "Server MUST advertise tools capability if it provides tools"
      process.exit exitCode
    
    complianceResults.toolsCapability = true
    logVerbose "✅ Tools capability advertised"
    
    # Validate listChanged property
    unless typeof result.capabilities.tools.listChanged is 'boolean'
      logError "Tools capability MUST include listChanged boolean property"
      process.exit exitCode
    
    logVerbose "✅ Tools listChanged: #{result.capabilities.tools.listChanged}"
    
    # Test 2: Send initialized notification (required by spec)
    makeRequest 'notifications/initialized', {}, null, (err, res) ->
      # This should not get a response (it's a notification)
      if res?
        logError "Server MUST NOT respond to notifications"
        process.exit exitCode
    
    # Test 3: List tools with strict validation
    makeRequest 'tools/list', {}, 2, (err, res) ->
      if err
        logError "tools/list failed: #{err.message}"
        process.exit exitCode
      
      if res.error
        logError "tools/list error: #{res.error.message}"
        process.exit exitCode
      
      # Validate tools/list response structure
      unless res.result?.tools? and Array.isArray(res.result.tools)
        logError "tools/list MUST return tools array"
        process.exit exitCode
      
      complianceResults.toolsList = true
      tools = res.result.tools
      logVerbose "✅ Listed #{tools.length} tools"
      
      # Validate each tool definition
      for tool in tools
        unless tool.name and typeof tool.name is 'string'
          logError "Tool missing required name field"
          process.exit exitCode
        
        unless tool.description and typeof tool.description is 'string'
          logError "Tool '#{tool.name}' missing required description"
          process.exit exitCode
        
        unless tool.inputSchema?.type is 'object'
          logError "Tool '#{tool.name}' missing valid inputSchema"
          process.exit exitCode
        
        logVerbose "  ✅ #{tool.name}: #{tool.description}"
      
      # Test 4: Call a tool to validate tools/call
      if tools.length > 0
        testTool = tools[0]
        makeRequest 'tools/call',
          name: testTool.name
          arguments: {}
        , 3, (err, res) ->
          if err
            logError "tools/call failed: #{err.message}"
            process.exit exitCode
          
          if res.error
            # Tool errors are acceptable, but response format must be valid
            complianceResults.errorHandling = true
            logVerbose "✅ Tool error handling: #{res.error.message}"
          else
            # Validate successful tool response
            unless res.result?.content? and Array.isArray(res.result.content)
              logError "Tool result MUST include content array"
              process.exit exitCode
            
            unless typeof res.result.isError is 'boolean'
              logError "Tool result MUST include isError boolean"
              process.exit exitCode
            
            complianceResults.toolsCall = true
            logVerbose "✅ Tool call successful"
          
          # Test 5: Explicit error handling test
          makeRequest 'nonexistent/method', {}, 4, (err, res) ->
            if err
              logError "Error handling test failed: #{err.message}"
              process.exit exitCode
            
            if res.error
              # This should be an error response - validate format
              unless res.error.code and typeof res.error.code is 'number'
                logError "Error response missing or invalid error code"
                process.exit exitCode
              
              unless res.error.message and typeof res.error.message is 'string'
                logError "Error response missing or invalid error message"
                process.exit exitCode
              
              complianceResults.errorHandling = true
              logVerbose "✅ Error handling: Method not found properly handled"
            else
              logError "Server MUST return error for non-existent methods"
              process.exit exitCode
            
            # All tests passed - report compliance
            reportCompliance()
      else
        logError "Server advertises tools capability but provides no tools"
        process.exit exitCode

# Report final compliance status
reportCompliance = ->
  allPassed = Object.values(complianceResults).every((result) -> result is true)
  
  if allPassed
    if verbose
      console.log "\n🎯 MCP 2025-06-18 COMPLIANCE VERIFIED"
      console.log "✅ Protocol Version: 2025-06-18"
      console.log "✅ JSON-RPC 2.0 Format: Valid"
      console.log "✅ HTTP Transport: Compliant"
      console.log "✅ Initialize Method: Compliant"
      console.log "✅ Capability Negotiation: Compliant"
      console.log "✅ Tools Capability: Compliant"
      console.log "✅ Tools List: Compliant"
      console.log "✅ Tools Call: Compliant"
      console.log "✅ Server Info: Compliant"
      console.log "✅ Error Handling: Compliant"
    process.exit 0
  else
    logError "\n❌ MCP COMPLIANCE FAILED"
    for key, value of complianceResults
      status = if value then "✅" else "❌"
      logError "#{status} #{key}"
    process.exit 1

# Handle process errors
process.on 'uncaughtException', (err) ->
  logError "Uncaught exception: #{err.message}"
  process.exit 1

process.on 'unhandledRejection', (reason, promise) ->
  logError "Unhandled rejection: #{reason}"
  process.exit 1

# OAuth2 prerequisite test runner
runOAuth2PrerequisiteTest = (callback) ->
  logVerbose "🔐 Running OAuth2 prerequisite test..."
  
  # Build arguments for OAuth2 test script
  oauth2Args = []
  
  # Pass through environment settings
  if config.environment isnt 'local'
    oauth2Args.push '--env', config.environment
  else if config.host isnt 'localhost' or config.port isnt 8080
    # Pass custom host/port settings
    oauth2Args.push '--host', config.host if config.host isnt 'localhost'
    oauth2Args.push '--port', config.port.toString() if config.port isnt 8080
  
  # Pass through HTTPS setting
  if config.useHttps
    oauth2Args.push '--https'
  
  # Pass through verbose setting
  if verbose
    oauth2Args.push '--verbose'
  
  # Get the path to the OAuth2 test script
  scriptDir = path.dirname(__filename)
  oauth2Script = path.join(scriptDir, 'test-oauth2.coffee')
  
  logVerbose "  Executing: coffee #{oauth2Script} #{oauth2Args.join(' ')}"
  
  # Spawn the OAuth2 test process
  oauth2Process = spawn 'coffee', [oauth2Script].concat(oauth2Args), {
    stdio: 'inherit'  # Pass through stdout/stderr to see OAuth2 test output
  }
  
  oauth2Process.on 'close', (code) ->
    if code is 0
      logVerbose "✅ OAuth2 prerequisite test passed"
      callback null
    else
      logError "❌ OAuth2 prerequisite test failed (exit code: #{code})"
      logError "   Cannot proceed with authenticated MCP testing"
      logError "   Fix OAuth2 implementation before testing MCP with --auth"
      callback new Error("OAuth2 prerequisite test failed")
  
  oauth2Process.on 'error', (err) ->
    logError "💥 Failed to run OAuth2 prerequisite test: #{err.message}"
    callback err

# Main execution logic
if useAuth
  # First run OAuth2 prerequisite test, then setup OAuth2 and run MCP tests
  runOAuth2PrerequisiteTest (err) ->
    if err
      process.exit 1
    else
      # OAuth2 prerequisite passed, now setup OAuth2 authentication for MCP tests
      setupOAuth2 (err) ->
        if err
          logError "OAuth2 setup failed, cannot proceed with authenticated MCP testing"
          process.exit 1
        else
          runMcpTests()
else
  # Run MCP tests without authentication
  runMcpTests()

# Set timeout for entire test suite
setTimeout ->
  logError "Test timeout - server not responding within reasonable time"
  process.exit 1
, 30000  # 30 second timeout
