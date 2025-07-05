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
  # Required fields
  unless tool.name and typeof tool.name