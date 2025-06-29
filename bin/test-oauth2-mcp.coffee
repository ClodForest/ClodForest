#!/usr/bin/env coffee
# FILENAME: { ClodForest/test-oauth2-mcp.coffee }
# Test OAuth2 authentication with MCP endpoint

http   = require 'http'
https  = require 'https'
{URL}  = require 'url'
crypto = require 'crypto'

# Configuration
HOST = 'localhost'
PORT = 8080

# Helper to make HTTP request
makeRequest = (method, path, data = null, headers = {}) ->
  new Promise (resolve, reject) ->
    options =
      hostname: HOST
      port: PORT
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
  console.log '🔐 Testing OAuth2 + MCP Integration\n'
  
  # Check if OAuth2 is enabled first
  isOAuth2Enabled = process.env.ENABLE_OAUTH2 is 'true'
  
  if isOAuth2Enabled
    # Step 1: Register a client (development mode only)
    console.log '1. Registering OAuth2 client...'
    clientReg = await makeRequest 'POST', '/oauth/clients',
      name: 'MCP Test Client'
      redirect_uris: ['http://localhost:3000/callback']
      scope: 'mcp read write'
    
    if clientReg.status isnt 201
      console.error '   ❌ Failed to register client:', clientReg.body
      console.log '   (OAuth2 endpoints may not be available - check ENABLE_OAUTH2)'
      return
    
    client = clientReg.body
    console.log '   ✅ Client registered'
    console.log "   Client ID: #{client.client_id}"
    console.log "   Client Secret: #{client.client_secret}"
  else
    console.log '1. OAuth2 is disabled - skipping client registration'
  
  # Step 2: Test MCP without auth (should fail if OAuth2 enabled)
  console.log '\n2. Testing MCP without authentication...'
  noAuthTest = await makeRequest 'POST', '/api/mcp',
    jsonrpc: '2.0'
    method: 'initialize'
    params: {}
    id: 1
  
  if process.env.ENABLE_OAUTH2 is 'true'
    if noAuthTest.status is 401
      console.log '   ✅ Correctly rejected - authentication required'
    else
      console.log '   ❌ Expected 401, got:', noAuthTest.status
  else
    if noAuthTest.status is 200
      console.log '   ✅ OAuth2 disabled - request succeeded'
    else
      console.log '   ❌ Unexpected error:', noAuthTest.status
  
  # If OAuth2 is not enabled, we're done
  unless process.env.ENABLE_OAUTH2 is 'true'
    console.log '\n💡 OAuth2 is disabled. Set ENABLE_OAUTH2=true to test authentication.'
    return
  
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
  
  # Step 4: Exchange code for tokens
  console.log '\n4. Exchanging authorization code for tokens...'
  
  # Create Basic auth header
  credentials = Buffer.from("#{client.client_id}:#{client.client_secret}").toString('base64')
  
  tokenRes = await makeRequest 'POST', '/oauth/token',
    grant_type: 'authorization_code'
    code: authCode
    redirect_uri: client.redirect_uris[0]
  ,
    'Authorization': "Basic #{credentials}"
  
  # Note: This will fail because we simulated the auth code
  # In a real flow, the code would be valid
  if tokenRes.status is 400
    console.log '   ⚠️  Expected failure - simulated auth code is invalid'
    console.log '   In production, use the real authorization flow'
    
    # For demo purposes, let's create a token directly
    # This is just for testing - normally tokens come from the token endpoint
    console.log '\n5. Creating demo token for testing...'
    demoToken = crypto.randomBytes(32).toString('hex')
    console.log "   🎫 Demo token: #{demoToken.substring(0, 16)}..."
  else
    token = tokenRes.body
    console.log '   ✅ Tokens received'
    console.log "   Access token: #{token.access_token.substring(0, 16)}..."
    console.log "   Token type: #{token.token_type}"
    console.log "   Expires in: #{token.expires_in}s"
  
  # Step 5: Test MCP with authentication
  console.log '\n6. Testing MCP with Bearer token...'
  
  # Use the real token if we got one, otherwise use demo token
  accessToken = token?.access_token or demoToken
  
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
    console.log '   ✅ Authentication successful!'
    console.log '   Protocol:', authTest.body.result?.protocolVersion
    console.log '   Server:', authTest.body.result?.serverInfo?.name
  else if authTest.status is 401
    console.log '   ❌ Authentication failed:', authTest.body
    console.log '   (This is expected with the demo token)'
  else
    console.log '   ❌ Unexpected response:', authTest.status, authTest.body
  
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
