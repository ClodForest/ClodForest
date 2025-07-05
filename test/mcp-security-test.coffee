#!/usr/bin/env coffee
# FILENAME: test/mcp-security-test.coffee

http  = require 'node:http'
https = require 'node:https'
{ URL } = require 'node:url'

CONFIG =
  baseUrl: 'http://localhost:8080'
  client:
    client_name : 'MCP Security Test Client'
    grant_types : ['client_credentials']
    scope       : 'mcp read write'

runSecurityTests = ->
  console.log '🔒 ClodForest MCP Security Tests'
  console.log "Server: #{CONFIG.baseUrl}"
  
  # Get OAuth2 token
  clientInfo  = await testStep 'OAuth2 Client Registration', registerClient()
  accessToken = await testStep 'OAuth2 Token Request',       getToken(clientInfo), extractToken
  
  return unless accessToken
  
  await testStep 'MCP Initialize', mcpInitialize(accessToken)
  
  # Test security boundaries
  await testStep 'Path Traversal Attack (..)',           mcpToolCall(accessToken, 'list_state_files', { path: '..' })
  await testStep 'Path Traversal Attack (../..)',        mcpToolCall(accessToken, 'list_state_files', { path: '../..' })
  await testStep 'Absolute Path Attack (/etc)',          mcpToolCall(accessToken, 'list_state_files', { path: '/etc' })
  await testStep 'Read Non-existent File',               mcpToolCall(accessToken, 'read_state_file', { path: 'nonexistent.txt' })
  await testStep 'Write to Invalid Path (../test.txt)',  mcpToolCall(accessToken, 'write_state_file', { path: '../test.txt', content: 'hack attempt' })
  
  # Test without authentication
  await testStep 'MCP Without Auth', mcpWithoutAuth()
  
  console.log '\n🔒 Security tests complete'

testStep = (name, request, extractor = null) ->
  console.log "\n=== #{name} ==="
  
  try
    response = await makeRequest request
    console.log "Status: #{response.status}"
    
    if response.body?.error
      console.log "Error:", response.body.error
      console.log "Description:", response.body.error_description or response.body.message
    else
      console.log "Response:", JSON.stringify(response.body, null, 2)
    
    if response.status >= 200 and response.status < 300
      console.log "✅ #{name} successful"
      return extractor?(response.body) or response.body
    else
      console.log "🔒 #{name} properly blocked (expected)"
      return null
  catch error
    console.log "❌ #{name} error:", error.message
    return null

registerClient = ->
  url    : "#{CONFIG.baseUrl}/oauth/register"
  method : 'POST'
  data   : JSON.stringify CONFIG.client

getToken = (clientInfo) ->
  auth = Buffer.from("#{clientInfo.client_id}:#{clientInfo.client_secret}").toString('base64')
  url     : "#{CONFIG.baseUrl}/oauth/token"
  method  : 'POST'
  headers :
    'Authorization' : "Basic #{auth}"
    'Content-Type'  : 'application/x-www-form-urlencoded'
  data    : 'grant_type=client_credentials&scope=mcp read write'

mcpInitialize = (token) ->
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
        name    : 'MCP Security Test Client'
        version : '1.0.0'

mcpToolCall = (token, toolName, args) ->
  url     : "#{CONFIG.baseUrl}/api/mcp"
  method  : 'POST'
  headers :
    'Authorization' : "Bearer #{token}"
    'Content-Type'  : 'application/json'
  data    : JSON.stringify
    jsonrpc : '2.0'
    id      : Math.floor(Math.random() * 1000)
    method  : 'tools/call'
    params  :
      name      : toolName
      arguments : args

mcpWithoutAuth = ->
  url     : "#{CONFIG.baseUrl}/api/mcp"
  method  : 'POST'
  headers :
    'Content-Type' : 'application/json'
  data    : JSON.stringify
    jsonrpc : '2.0'
    id      : 999
    method  : 'tools/list'
    params  : {}

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

if require.main is module
  runSecurityTests().catch (error) ->
    console.error 'Security test error:', error
    process.exit 1
else
  module.exports = { runSecurityTests }
