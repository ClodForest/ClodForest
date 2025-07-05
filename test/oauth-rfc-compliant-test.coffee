#!/usr/bin/env coffee
# FILENAME: test/oauth-rfc-compliant-test.coffee
# Test OAuth2 client registration with RFC-compliant grant_types

http = require 'node:http'
{ URL } = require 'node:url'

CONFIG =
  baseUrl: 'http://localhost:8080'
  timeout: 15000

# Test OAuth2 client registration with RFC-compliant request
runRfcCompliantTest = ->
  console.log '🔍 RFC-Compliant OAuth2 Registration Test'
  console.log "Server: #{CONFIG.baseUrl}"
  
  # Test with proper grant_types (no refresh_token)
  await testStep 'RFC Compliant Registration', testRfcCompliantRegistration()
  
  console.log '\n🔍 RFC-compliant test complete'

testStep = (name, testFunction) ->
  console.log "\n=== #{name} ==="
  
  try
    result = await testFunction
    if result.success
      console.log "✅ #{name}: #{result.message}"
      return result.data
    else
      console.log "❌ #{name}: #{result.message}"
      return null
  catch error
    console.log "❌ #{name} error:", error.message
    return null

testRfcCompliantRegistration = ->
  # Test client registration with RFC-compliant grant_types
  rfcCompliantRequest =
    redirect_uris: ["http://127.0.0.1:6274/oauth/callback/debug"]
    token_endpoint_auth_method: "none"
    grant_types: ["authorization_code"]  # RFC-compliant: no refresh_token
    response_types: ["code"]
    client_name: "RFC Compliant Test Client"
    client_uri: "https://github.com/modelcontextprotocol/inspector"
    scope: "mcp read write"

  try
    # Get the registration endpoint from discovery
    discoveryResponse = await makeRequest
      url: "#{CONFIG.baseUrl}/.well-known/oauth-authorization-server"
      method: 'GET'
    
    registrationEndpoint = discoveryResponse.body?.registration_endpoint or "#{CONFIG.baseUrl}/oauth/register"
    
    response = await makeRequest
      url: registrationEndpoint
      method: 'POST'
      data: JSON.stringify(rfcCompliantRequest)
      headers:
        'Content-Type': 'application/json'
    
    console.log "Registration Status: #{response.status}"
    console.log "Registration Response:", JSON.stringify(response.body, null, 2)
    
    if response.status is 201
      success: true
      message: 'RFC-compliant client registration successful'
      data: response.body
    else
      success: false
      message: "Registration failed with status #{response.status}: #{response.body?.error_description or response.body?.error}"
  catch error
    success: false
    message: "Registration error: #{error.message}"

makeRequest = (options) ->
  new Promise (resolve, reject) ->
    url = new URL options.url
    protocol = if url.protocol is 'https:' then require('node:https') else http
    
    reqOptions =
      hostname: url.hostname
      port: url.port or (if url.protocol is 'https:' then 443 else 80)
      path: url.pathname + url.search
      method: options.method or 'GET'
      headers: options.headers or {}
      timeout: CONFIG.timeout
    
    if options.data
      reqOptions.headers['Content-Type'] or= 'application/json'
      reqOptions.headers['Content-Length'] = Buffer.byteLength options.data
    
    req = protocol.request reqOptions, (res) ->
      body = ''
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', ->
        try
          result =
            status: res.statusCode
            headers: res.headers
            body: if body then JSON.parse(body) else null
          resolve result
        catch error
          resolve
            status: res.statusCode
            headers: res.headers
            body: body
            parseError: error.message
    
    req.on 'error', reject
    req.on 'timeout', -> reject new Error('Request timeout')
    
    req.write options.data if options.data
    req.end()

if require.main is module
  runRfcCompliantTest().catch (error) ->
    console.error 'RFC-compliant test error:', error
    process.exit 1
else
  module.exports = { runRfcCompliantTest }
