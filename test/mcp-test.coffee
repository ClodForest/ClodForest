#!/usr/bin/env coffee
# FILENAME: test/mcp-test.coffee

http  = require 'node:http'
https = require 'node:https'
{ URL } = require 'node:url'

CONFIG =
  baseUrl: 'http://localhost:8080'
  client:
    client_name : 'MCP Test Client'
    grant_types : ['client_credentials']
    scope       : 'mcp read write'

TEST_REQUESTS =
  clientRegistration: ->
    url    : "#{CONFIG.baseUrl}/oauth/register"
    method : 'POST'
    data   : JSON.stringify CONFIG.client

  tokenRequest: (clientInfo) ->
    auth = Buffer.from("#{clientInfo.client_id}:#{clientInfo.client_secret}").toString('base64')
    url     : "#{CONFIG.baseUrl}/oauth/token"
    method  : 'POST'
    headers :
      'Authorization' : "Basic #{auth}"
      'Content-Type'  : 'application/x-www-form-urlencoded'
    data    : 'grant_type=client_credentials&scope=mcp read write'

  mcpInitialize: (token) ->
    url     : "#{CONFIG.baseUrl}/api/mcp"
    method  : 'POST'
    headers :
      'Authorization' : "Bearer #{token}"
      'Content-Type'  : 'application/json'
    data    : JSON.stringify
      jsonrpc : '2.0'
      id      : 1
      method  : 'initialize'
      params  :
        protocolVersion : '2025-06-18'
        capabilities    : {}
        clientInfo      :
          name    : 'MCP Test Client'
          version : '1.0.0'

  mcpToolsList: (token) ->
    url     : "#{CONFIG.baseUrl}/api/mcp"
    method  : 'POST'
    headers :
      'Authorization' : "Bearer #{token}"
      'Content-Type'  : 'application/json'
    data    : JSON.stringify
      jsonrpc : '2.0'
      id      : 2
      method  : 'tools/list'
      params  : {}

  mcpToolCall: (token) ->
    url     : "#{CONFIG.baseUrl}/api/mcp"
    method  : 'POST'
    headers :
      'Authorization' : "Bearer #{token}"
      'Content-Type'  : 'application/json'
    data    : JSON.stringify
      jsonrpc : '2.0'
      id      : 3
      method  : 'tools/call'
      params  :
        name      : 'list_state_files'
        arguments :
          path : '.'

runTests = ->
  console.log '🧪 ClodForest MCP Implementation Tests'
  console.log "Server: #{CONFIG.baseUrl}"
  
  clientInfo  = await testStep 'OAuth2 Client Registration', TEST_REQUESTS.clientRegistration()
  accessToken = await testStep 'OAuth2 Token Request',       TEST_REQUESTS.tokenRequest(clientInfo), extractToken
  
  return unless accessToken
  
  await testStep 'MCP Initialize',  TEST_REQUESTS.mcpInitialize(accessToken)
  tools = await testStep 'MCP Tools List', TEST_REQUESTS.mcpToolsList(accessToken), extractTools
  await testStep 'MCP Tool Call',   TEST_REQUESTS.mcpToolCall(accessToken)
  
  console.log '\n🏁 Tests complete'

testStep = (name, request, extractor = null) ->
  console.log "\n=== #{name} ==="
  
  try
    response = await makeRequest request
    console.log "Status: #{response.status}"
    console.log "Response:", JSON.stringify(response.body, null, 2)
    
    if response.status >= 200 and response.status < 300
      console.log "✅ #{name} successful"
      return extractor?(response.body) or response.body
    else
      console.log "❌ #{name} failed"
      return null
  catch error
    console.log "❌ #{name} error:", error.message
    return null

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

extractToken = (body) -> body?.access_token

extractTools = (body) ->
  tools = body?.result?.tools
  if tools
    console.log "Available tools: #{tools.map((t) -> t.name).join(', ')}"
  tools

if require.main is module
  runTests().catch (error) ->
    console.error 'Test error:', error
    process.exit 1
else
  module.exports = { runTests }
