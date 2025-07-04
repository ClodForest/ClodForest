#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-oauth2-mcp.coffee }
# OAuth2 + MCP Integration Test Script
# Demonstrates complete OAuth2 authentication flow with MCP endpoints
# 
# For isolated testing, use:
# - bin/test-oauth2.coffee     (OAuth2 functionality only)
# - bin/test-mcp.coffee --auth (MCP compliance with OAuth2)

http   = require 'http'
https  = require 'https'
{URL}  = require 'url'
crypto = require 'crypto'

# Parse command line arguments
args = process.argv.slice(2)
verbose = true  # Always verbose for integration demo

# Default configuration
config =
  host: 'localhost'
  port: 8080
  useHttps: false

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
    
    req = http.request options, (res) ->
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

# Main test flow
main = ->
  console.log '🔐 OAuth2 + MCP Integration Test'
  console.log '================================'
  console.log 'This script demonstrates the complete OAuth2 + MCP workflow.'
  console.log 'For isolated testing:'
  console.log '• coffee bin/test-oauth2.coffee     - OAuth2 functionality only'
  console.log '• coffee bin/test-mcp.coffee --auth - MCP compliance with OAuth2'
  console.log ''
  
  # Step 1: Register a client (development mode only)
  console.log '1. Registering OAuth2 client...'
  clientReg = await makeRequest 'POST', '/oauth/clients',
    name: 'MCP Test Client'
    redirect_uris: ['http://localhost:3000/callback']
    scope: 'mcp read write'
  
  if clientReg.status isnt 201
    console.error '   ❌ Failed to register client:', clientReg.body
    console.log '   (OAuth2 endpoints may not be available - ensure server is running with OAuth2 enabled)'
    return
  
  client = clientReg.body
  console.log '   ✅ Client registered'
  console.log "   Client ID: #{client.client_id}"
  console.log "   Client Secret: #{client.client_secret}"
  
  # Step 2: Test MCP without auth (should fail with OAuth2 enabled)
  console.log '\n2. Testing MCP without authentication...'
  noAuthTest = await makeRequest 'POST', '/api/mcp',
    jsonrpc: '2.0'
    method: 'initialize'
    params: {}
    id: 1
  
  if noAuthTest.status is 401
    console.log '   ✅ Correctly rejected - authentication required'
  else
    console.log '   ❌ Expected 401, got:', noAuthTest.status
  
  # Step 3: Simulate authorization flow
  console.log '\n3. Simulating authorization flow...'
  console.log '   In a real app, user would:'
  console.log '   a) Be redirected to /oauth/authorize'
  console.log '   b) Login with credentials'
  console.log '   c) Approve the authorization'
  console.log '   d) Be redirected back with an authorization code'
  
  # For testing, we'll directly create an auth code
  # In production, this would come from the authorization endpoint
  authCode = crypto.randomBytes(32).toString('hex')
  console.log "   📝 Simulated auth code: #{authCode.substring(0, 16)}..."
  
  # Step 4: Test Client Credentials Grant (Claude.ai flow)
  console.log '\n4. Testing Client Credentials Grant (Claude.ai flow)...'
  
  # Create Basic auth header
  credentials = Buffer.from("#{client.client_id}:#{client.client_secret}").toString('base64')
  
  tokenRes = await makeRequest 'POST', '/oauth/token',
    grant_type: 'client_credentials'
    scope: 'mcp'
  ,
    'Authorization': "Basic #{credentials}"
  
  if tokenRes.status is 200
    token = tokenRes.body
    console.log '   ✅ Client credentials token received'
    console.log "   Access token: #{token.access_token.substring(0, 16)}..."
    console.log "   Token type: #{token.token_type}"
    console.log "   Expires in: #{token.expires_in}s"
    console.log "   Scope: #{token.scope}"
  else
    console.log '   ❌ Client credentials failed:', tokenRes.body
    return
  
  # Step 5: Test MCP with authentication on /api/mcp
  console.log '\n5. Testing /api/mcp with Bearer token...'
  
  accessToken = token.access_token
  
  authTest = await makeRequest 'POST', '/api/mcp',
    jsonrpc: '2.0'
    method: 'initialize'
    params:
      clientInfo:
        name: 'oauth2-test'
        version: '1.0.0'
    id: 1
  ,
    'Authorization': "Bearer #{accessToken}"
  
  if authTest.status is 200
    console.log '   ✅ /api/mcp authentication successful!'
    console.log '   Protocol:', authTest.body.result?.protocolVersion
    console.log '   Server:', authTest.body.result?.serverInfo?.name
  else
    console.log '   ❌ /api/mcp authentication failed:', authTest.status, authTest.body
  
  # Step 6: Test Claude.ai expected endpoint
  console.log '\n6. Testing /mcp/jsonrpc (Claude.ai endpoint) with Bearer token...'
  
  claudeTest = await makeRequest 'POST', '/mcp/jsonrpc',
    jsonrpc: '2.0'
    method: 'initialize'
    params:
      clientInfo:
        name: 'claude-ai-test'
        version: '1.0.0'
    id: 1
  ,
    'Authorization': "Bearer #{accessToken}"
  
  if claudeTest.status is 200
    console.log '   ✅ /mcp/jsonrpc authentication successful!'
    console.log '   Protocol:', claudeTest.body.result?.protocolVersion
    console.log '   Server:', claudeTest.body.result?.serverInfo?.name
    
    # Test tools/list on Claude.ai endpoint
    console.log '\n7. Testing tools/list on Claude.ai endpoint...'
    toolsTest = await makeRequest 'POST', '/mcp/jsonrpc',
      jsonrpc: '2.0'
      method: 'tools/list'
      params: {}
      id: 2
    ,
      'Authorization': "Bearer #{accessToken}"
    
    if toolsTest.status is 200
      console.log '   ✅ tools/list successful!'
      console.log "   Found #{toolsTest.body.result?.tools?.length or 0} tools"
      console.log '   Sample tools:'
      for tool in (toolsTest.body.result?.tools or []).slice(0, 3)
        console.log "     - #{tool.name}: #{tool.description}"
    else
      console.log '   ❌ tools/list failed:', toolsTest.status, toolsTest.body
  else
    console.log '   ❌ /mcp/jsonrpc authentication failed:', claudeTest.status, claudeTest.body
  
  # Show OAuth2 flow summary
  console.log '\n📋 OAuth2 Flow Summary:'
  console.log '1. Register client application (one time)'
  console.log '2. Direct user to /oauth/authorize with client_id'
  console.log '3. User logs in and approves access'
  console.log '4. User redirected back with authorization code'
  console.log '5. Exchange code for access token at /oauth/token'
  console.log '6. Use Bearer token in Authorization header for MCP requests'
  
  console.log '\n✨ OAuth2 integration test complete!'

# Run the test
main().catch (err) ->
  console.error '💥 Error:', err.message
