#!/usr/bin/env coffee
# FILENAME: test/mcp-inspector-oauth-test.coffee
# Test OAuth2 client registration using MCP Inspector's actual registration flow

{ spawn } = require 'node:child_process'
http = require 'node:http'
{ URL } = require 'node:url'

CONFIG =
  baseUrl: 'http://localhost:8080'
  timeout: 15000

# Test OAuth2 client registration using the exact flow MCP Inspector uses
runOAuth2RegistrationTest = ->
  console.log '🔍 MCP Inspector OAuth2 Registration Test'
  console.log "Server: #{CONFIG.baseUrl}"
  
  # Test the OAuth2 discovery endpoint first
  await testStep 'OAuth2 Discovery', testOAuth2Discovery()
  
  # Test client registration with MCP Inspector's exact request
  await testStep 'Client Registration', testClientRegistration()
  
  console.log '\n🔍 OAuth2 registration test complete'

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

testOAuth2Discovery = ->
  # Test OAuth2 discovery endpoint
  try
    response = await makeRequest
      url: "#{CONFIG.baseUrl}/.well-known/oauth-authorization-server"
      method: 'GET'
    
    if response.status is 200 and response.body?.registration_endpoint
      success: true
      message: "OAuth2 discovery successful - registration endpoint: #{response.body.registration_endpoint}"
      data: response.body
    else
      success: false
      message: "OAuth2 discovery failed - status #{response.status}"
  catch error
    success: false
    message: "Discovery error: #{error.message}"

testClientRegistration = ->
  # Test client registration with the exact request MCP Inspector makes
  mcpInspectorRequest =
    redirect_uris: ["http://127.0.0.1:6274/oauth/callback/debug"]
    token_endpoint_auth_method: "none"
    grant_types: ["authorization_code", "refresh_token"]
    response_types: ["code"]
    client_name: "MCP Inspector"
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
      data: JSON.stringify(mcpInspectorRequest)
      headers:
        'Content-Type': 'application/json'
    
    console.log "Registration Status: #{response.status}"
    console.log "Registration Response:", JSON.stringify(response.body, null, 2)
    
    if response.status is 201
      success: true
      message: 'MCP Inspector client registration successful'
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
  runOAuth2RegistrationTest().catch (error) ->
    console.error 'OAuth2 registration test error:', error
    process.exit 1
else
  module.exports = { runOAuth2RegistrationTest }
