#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-well-known.coffee }
# RFC 5785 Well-Known URIs Compliance Test Script
# Tests discovery endpoints and metadata according to RFC 5785 and RFC 8707

http   = require 'node:http'
https  = require 'node:https'
{URL}  = require 'node:url'

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
    ClodForest RFC 5785 Well-Known URIs Compliance Test Script

    Usage:
      coffee bin/test-well-known.coffee [options]

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
      0                          RFC 5785 compliance verified
      1                          RFC 5785 compliance failure

    RFC 5785 Tests:
      • /.well-known/oauth-authorization-server (RFC 8414)
      • /.well-known/oauth-protected-resource (RFC 8707)
      • /.well-known/mcp-server (ClodForest extension)
      • Proper Content-Type headers
      • CORS headers for cross-origin discovery
      • JSON format validation
      • Required metadata fields

    Examples:
      coffee bin/test-well-known.coffee                    # Test local
      coffee bin/test-well-known.coffee --verbose          # Test with details
      coffee bin/test-well-known.coffee --env production   # Test production
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

# RFC 5785 compliance tracking
wellKnownResults = {
  serverReachable: false
  oauthAuthzServer: false
  oauthMetadataValid: false
  oauthProtectedResource: false
  protectedResourceMetadataValid: false
  mcpServer: false
  mcpMetadataValid: false
  contentTypeHeaders: false
  corsHeaders: false
  jsonFormat: false
  requiredFields: false
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

# Helper to make HTTP request
makeRequest = (method, path, headers = {}) ->
  new Promise (resolve, reject) ->
    options =
      hostname: config.host
      port: config.port
      path: path
      method: method
      headers: Object.assign({
        'User-Agent': 'ClodForest-WellKnown-Test/1.0'
      }, headers)

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
            body: null
            rawBody: body
            parseError: e.message
          }

    req.on 'error', reject
    req.end()

# Validate JSON format according to RFC 7159
validateJsonFormat = (response) ->
  return false unless response.rawBody
  return false if response.parseError
  return true

# Validate Content-Type header according to RFC 5785
validateContentType = (headers) ->
  contentType = headers['content-type']
  return false unless contentType
  # Should be application/json for metadata endpoints
  return contentType.includes('application/json')

# Validate CORS headers for cross-origin discovery
validateCorsHeaders = (headers) ->
  # RFC 5785 recommends CORS support for discovery endpoints
  accessControlAllowOrigin = headers['access-control-allow-origin']
  return accessControlAllowOrigin?

# Validate OAuth Authorization Server Metadata (RFC 8414)
validateOAuthMetadata = (metadata) ->
  return false unless metadata

  # Required fields per RFC 8414
  requiredFields = [
    'issuer'
    'authorization_endpoint'
    'token_endpoint'
    'response_types_supported'
    'grant_types_supported'
  ]

  for field in requiredFields
    return false unless metadata[field]

  # Validate URLs are properly formatted
  try
    new URL(metadata.authorization_endpoint)
    new URL(metadata.token_endpoint)
  catch
    return false

  # Validate arrays contain expected values
  return false unless Array.isArray(metadata.response_types_supported)
  return false unless Array.isArray(metadata.grant_types_supported)

  return true

# Validate OAuth Protected Resource Metadata (RFC 8707)
validateProtectedResourceMetadata = (metadata) ->
  return false unless metadata

  # Required fields per RFC 8707
  requiredFields = [
    'resource'
    'authorization_servers'
    'scopes_supported'
    'bearer_methods_supported'
  ]

  for field in requiredFields
    return false unless metadata[field]

  # Validate resource URL
  try
    new URL(metadata.resource)
  catch
    return false

  # Validate authorization_servers array
  return false unless Array.isArray(metadata.authorization_servers)
  return false if metadata.authorization_servers.length is 0

  # Validate each authorization server URL
  for authServer in metadata.authorization_servers
    try
      new URL(authServer)
    catch
      return false

  # Validate scopes_supported array
  return false unless Array.isArray(metadata.scopes_supported)
  return false if metadata.scopes_supported.length is 0

  # Validate bearer_methods_supported array
  return false unless Array.isArray(metadata.bearer_methods_supported)
  return false unless 'header' in metadata.bearer_methods_supported

  return true

# Validate MCP Server Metadata (ClodForest extension)
validateMcpMetadata = (metadata) ->
  return false unless metadata

  # ClodForest MCP discovery format
  requiredFields = [
    'server_info'
    'protocol_version'
    'capabilities'
    'endpoints'
  ]

  for field in requiredFields
    return false unless metadata[field]

  # Validate server_info structure
  return false unless metadata.server_info.name
  return false unless metadata.server_info.version

  # Validate protocol version
  return false unless metadata.protocol_version is '2025-06-18'

  # Validate endpoints structure
  return false unless metadata.endpoints.mcp

  try
    new URL(metadata.endpoints.mcp)
  catch
    return false

  return true

# Main test sequence
main = ->
  protocol = if config.useHttps then 'https' else 'http'
  logVerbose "🔍 Testing RFC 5785 Well-Known URIs: #{protocol}://#{config.host}:#{config.port}"
  testNum = 0

  try
    logVerbose "\n#{testNum++}. Testing server connectivity..."
    healthCheck = await makeRequest 'GET', '/api/health'

    if healthCheck.status is 200
      wellKnownResults.serverReachable = true
      logSuccess "✅ Server reachable"
    else
      logError "❌ Server not reachable (HTTP #{healthCheck.status})"
      return reportResults()

    logVerbose "\n#{testNum++}. Testing /.well-known/oauth-authorization-server (RFC 8414)..."
    oauthMetadata = await makeRequest 'GET', '/.well-known/oauth-authorization-server'

    if oauthMetadata.status is 200
      wellKnownResults.oauthAuthzServer = true
      logSuccess "✅ OAuth authorization server metadata endpoint exists"

      # Validate Content-Type
      if validateContentType(oauthMetadata.headers)
        wellKnownResults.contentTypeHeaders = true
        logSuccess "✅ Proper Content-Type header (application/json)"
      else
        logError "❌ Invalid Content-Type header: #{oauthMetadata.headers['content-type']}"

      # Validate CORS headers
      if validateCorsHeaders(oauthMetadata.headers)
        wellKnownResults.corsHeaders = true
        logSuccess "✅ CORS headers present for cross-origin discovery"
      else
        logError "❌ Missing CORS headers for cross-origin discovery"

      # Validate JSON format
      if validateJsonFormat(oauthMetadata)
        wellKnownResults.jsonFormat = true
        logSuccess "✅ Valid JSON format"

        # Validate OAuth metadata structure
        if validateOAuthMetadata(oauthMetadata.body)
          wellKnownResults.oauthMetadataValid = true
          wellKnownResults.requiredFields = true
          logSuccess "✅ Valid OAuth authorization server metadata (RFC 8414)"
          logVerbose "   Issuer: #{oauthMetadata.body.issuer}"
          logVerbose "   Authorization endpoint: #{oauthMetadata.body.authorization_endpoint}"
          logVerbose "   Token endpoint: #{oauthMetadata.body.token_endpoint}"
          logVerbose "   Response types: #{oauthMetadata.body.response_types_supported.join(', ')}"
          logVerbose "   Grant types: #{oauthMetadata.body.grant_types_supported.join(', ')}"
        else
          logError "❌ Invalid OAuth authorization server metadata structure"
          logVerbose "   Response: #{JSON.stringify(oauthMetadata.body, null, 2)}"
      else
        logError "❌ Invalid JSON format"
        logError "   Parse error: #{oauthMetadata.parseError}" if oauthMetadata.parseError
        logVerbose "   Raw response: #{oauthMetadata.rawBody}"

    else if oauthMetadata.status is 404
      logError "❌ OAuth authorization server metadata endpoint not found"
      logError "   RFC 8414 requires /.well-known/oauth-authorization-server"
    else
      logError "❌ OAuth authorization server metadata endpoint error (HTTP #{oauthMetadata.status})"

    logVerbose "\n#{testNum++}. Testing /.well-known/oauth-protected-resource (RFC 8707)..."
    protectedResourceMetadata = await makeRequest 'GET', '/.well-known/oauth-protected-resource'

    if protectedResourceMetadata.status is 200
      wellKnownResults.oauthProtectedResource = true
      logSuccess "✅ OAuth protected resource metadata endpoint exists"

      # Validate JSON format
      if validateJsonFormat(protectedResourceMetadata)
        logSuccess "✅ Valid JSON format for protected resource metadata"

        # Validate protected resource metadata structure
        if validateProtectedResourceMetadata(protectedResourceMetadata.body)
          wellKnownResults.protectedResourceMetadataValid = true
          logSuccess "✅ Valid OAuth protected resource metadata (RFC 8707)"
          logVerbose "   Resource: #{protectedResourceMetadata.body.resource}"
          logVerbose "   Authorization servers: #{protectedResourceMetadata.body.authorization_servers.join(', ')}"
          logVerbose "   Scopes: #{protectedResourceMetadata.body.scopes_supported.join(', ')}"
          logVerbose "   Bearer methods: #{protectedResourceMetadata.body.bearer_methods_supported.join(', ')}"
        else
          logError "❌ Invalid OAuth protected resource metadata structure"
          logVerbose "   Response: #{JSON.stringify(protectedResourceMetadata.body, null, 2)}"
      else
        logError "❌ Invalid JSON format for protected resource metadata"
        logError "   Parse error: #{protectedResourceMetadata.parseError}" if protectedResourceMetadata.parseError

    else if protectedResourceMetadata.status is 404
      logError "❌ OAuth protected resource metadata endpoint not found"
      logError "   RFC 8707 requires /.well-known/oauth-protected-resource"
      logError "   This is CRITICAL for Claude.ai MCP client discovery!"
    else
      logError "❌ OAuth protected resource metadata endpoint error (HTTP #{protectedResourceMetadata.status})"

    logVerbose "\n#{testNum++}. Testing /.well-known/mcp-server (ClodForest extension)..."
    mcpMetadata = await makeRequest 'GET', '/.well-known/mcp-server'

    if mcpMetadata.status is 200
      wellKnownResults.mcpServer = true
      logSuccess "✅ MCP server metadata endpoint exists"

      # Validate JSON format
      if validateJsonFormat(mcpMetadata)
        logSuccess "✅ Valid JSON format for MCP metadata"

        # Validate MCP metadata structure
        if validateMcpMetadata(mcpMetadata.body)
          wellKnownResults.mcpMetadataValid = true
          logSuccess "✅ Valid MCP server metadata"
          logVerbose "   Server: #{mcpMetadata.body.server_info.name} v#{mcpMetadata.body.server_info.version}"
          logVerbose "   Protocol: #{mcpMetadata.body.protocol_version}"
          logVerbose "   MCP endpoint: #{mcpMetadata.body.endpoints.mcp}"
          logVerbose "   Capabilities: #{Object.keys(mcpMetadata.body.capabilities).join(', ')}"
        else
          logError "❌ Invalid MCP server metadata structure"
          logVerbose "   Response: #{JSON.stringify(mcpMetadata.body, null, 2)}"
      else
        logError "❌ Invalid JSON format for MCP metadata"
        logError "   Parse error: #{mcpMetadata.parseError}" if mcpMetadata.parseError

    else if mcpMetadata.status is 404
      logError "❌ MCP server metadata endpoint not found"
      logError "   ClodForest extension: /.well-known/mcp-server"
    else
      logError "❌ MCP server metadata endpoint error (HTTP #{mcpMetadata.status})"

    logVerbose "\n#{testNum++}. Testing /.well-known/ directory listing..."
    wellKnownRoot = await makeRequest 'GET', '/.well-known/'

    if wellKnownRoot.status is 200
      logSuccess "✅ Well-known root directory accessible"
      logVerbose "   Note: RFC 5785 does not require a specific format for /.well-known/"
    else if wellKnownRoot.status is 404
      logVerbose "ℹ️  Well-known root directory returns 404 (acceptable per RFC 5785)"
    else
      logVerbose "ℹ️  Well-known root directory returns HTTP #{wellKnownRoot.status}"

  catch error
    logError "💥 Test execution error: #{error.message}"
    exitCode = 1

  reportResults()

# Report final RFC 5785 compliance results
reportResults = ->
  # Calculate compliance score
  totalTests = Object.keys(wellKnownResults).length
  passedTests = Object.values(wellKnownResults).filter((result) -> result is true).length
  compliancePercentage = Math.round((passedTests / totalTests) * 100)

  console.log "\n📋 RFC 5785 Well-Known URIs Test Results:"

  for key, value of wellKnownResults
    status = if value then "✅" else "❌"
    console.log "#{status} #{key}"

  console.log "\n📊 Compliance Score: #{passedTests}/#{totalTests} (#{compliancePercentage}%)"

  if passedTests is totalTests
    console.log "\n🎯 RFC 5785 WELL-KNOWN URIS FULLY COMPLIANT"
    console.log "✅ All discovery endpoints properly implemented"
    console.log "✅ Metadata formats comply with relevant RFCs"
    console.log "✅ HTTP headers follow RFC 5785 recommendations"
    console.log "✅ Claude.ai MCP client discovery will work!"
    process.exit 0
  else
    console.log "\n⚠️  RFC 5785 COMPLIANCE INCOMPLETE"
    console.log "Missing well-known endpoints or metadata:"

    unless wellKnownResults.serverReachable
      console.log "• Server connectivity issues"

    unless wellKnownResults.oauthAuthzServer
      console.log "• /.well-known/oauth-authorization-server endpoint (RFC 8414)"

    unless wellKnownResults.oauthMetadataValid
      console.log "• Valid OAuth authorization server metadata structure"

    unless wellKnownResults.oauthProtectedResource
      console.log "• /.well-known/oauth-protected-resource endpoint (RFC 8707) ⚠️  CRITICAL"

    unless wellKnownResults.protectedResourceMetadataValid
      console.log "• Valid OAuth protected resource metadata structure ⚠️  CRITICAL"

    unless wellKnownResults.mcpServer
      console.log "• /.well-known/mcp-server endpoint (ClodForest extension)"

    unless wellKnownResults.mcpMetadataValid
      console.log "• Valid MCP server metadata structure"

    unless wellKnownResults.contentTypeHeaders
      console.log "• Proper Content-Type headers (application/json)"

    unless wellKnownResults.corsHeaders
      console.log "• CORS headers for cross-origin discovery"

    unless wellKnownResults.jsonFormat
      console.log "• Valid JSON format in responses"

    unless wellKnownResults.requiredFields
      console.log "• Required metadata fields per RFCs"

    if not wellKnownResults.oauthProtectedResource or not wellKnownResults.protectedResourceMetadataValid
      console.log "\n🚨 CRITICAL: Claude.ai requires /.well-known/oauth-protected-resource"
      console.log "   Without this endpoint, Claude.ai cannot discover how to authenticate"
      console.log "   with the MCP server and will refuse to connect."

    console.log "\n💡 Implement missing endpoints to achieve full RFC 5785 compliance"
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