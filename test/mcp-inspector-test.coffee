#!/usr/bin/env coffee
# FILENAME: test/mcp-inspector-test.coffee

http  = require 'node:http'
https = require 'node:https'
{ URL } = require 'node:url'

CONFIG =
  baseUrl: 'http://localhost:8080'

runMcpInspectorTest = ->
  console.log '🔍 MCP Inspector Compatibility Test'
  console.log "Server: #{CONFIG.baseUrl}"
  
  # Test the exact request that MCP Inspector makes
  await testStep 'MCP Inspector Client Registration', testMcpInspectorRegistration()
  
  console.log '\n🔍 MCP Inspector compatibility test complete'

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

testMcpInspectorRegistration = ->
  # This is the exact request from your logs
  mcpInspectorRequest =
    redirect_uris: ["http://127.0.0.1:6274/oauth/callback/debug"]
    token_endpoint_auth_method: "none"
    grant_types: ["authorization_code", "refresh_token"]
    response_types: ["code"]
    client_name: "MCP Inspector"
    client_uri: "https://github.com/modelcontextprotocol/inspector"
    scope: "mcp read write"

  try
    response = await makeRequest
      url    : "#{CONFIG.baseUrl}/oauth/register"
      method : 'POST'
      data   : JSON.stringify(mcpInspectorRequest)
    
    console.log "Status: #{response.status}"
    console.log "Response:", JSON.stringify(response.body, null, 2)
    
    if response.status is 201
      success : true
      message : 'MCP Inspector client registration successful'
      data    : response.body
    else
      success : false
      message : "Registration failed with status #{response.status}: #{response.body?.error_description or response.body?.error}"
  catch error
    success : false
    message : "Registration error: #{error.message}"

makeRequest = (options) ->
  new Promise (resolve, reject) ->
    url = new URL options.url
    protocol = if url.protocol is 'https:' then https else http
    
    reqOptions =
      hostname : url.hostname
      port     : url.port or (if url.protocol is 'https:' then 443 else 80)
      path     : url.pathname + url.search
      method   : options.method or 'GET'
      headers  : options.headers or {}
    
    if options.data
      reqOptions.headers['Content-Type'] or= 'application/json'
      reqOptions.headers['Content-Length'] = Buffer.byteLength options.data
    
    req = protocol.request reqOptions, (res) ->
      body = ''
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', ->
        try
          result =
            status  : res.statusCode
            headers : res.headers
            body    : if body then JSON.parse(body) else null
          resolve result
        catch error
          resolve
            status     : res.statusCode
            headers    : res.headers
            body       : body
            parseError : error.message
    
    req.on 'error', reject
    req.write options.data if options.data
    req.end()

if require.main is module
  runMcpInspectorTest().catch (error) ->
    console.error 'MCP Inspector test error:', error
    process.exit 1
else
  module.exports = { runMcpInspectorTest }
