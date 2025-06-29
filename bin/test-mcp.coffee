#!/usr/bin/env coffee
# FILENAME: { ClodForest/test-mcp.coffee }
# Quick test script for MCP endpoint

http = require 'http'

# Configuration
HOST = 'localhost'
PORT = 8080
PATH = '/api/mcp'

# Helper to make JSON-RPC request
makeRequest = (method, params, id, callback) ->
  requestData = JSON.stringify
    jsonrpc: '2.0'
    method: method
    params: params
    id: id
  
  options =
    hostname: HOST
    port: PORT
    path: PATH
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Content-Length': Buffer.byteLength(requestData)
  
  req = http.request options, (res) ->
    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      try
        response = JSON.parse(data)
        callback null, response
      catch e
        callback e
  
  req.on 'error', callback
  req.write requestData
  req.end()

# Test sequence
console.log '🧪 Testing ClodForest MCP Endpoint...\n'

# Test 1: Initialize
console.log '1. Testing initialize...'
makeRequest 'initialize', 
  clientInfo:
    name: 'test-client'
    version: '1.0.0'
, 1, (err, res) ->
  if err
    console.error '   ❌ Error:', err.message
    return
  
  if res.error
    console.error '   ❌ JSON-RPC Error:', res.error
    return
  
  console.log '   ✅ Initialized successfully'
  console.log '   Protocol version:', res.result?.protocolVersion
  console.log '   Server:', res.result?.serverInfo?.name
  
  # Test 2: List tools
  console.log '\n2. Testing tools/list...'
  makeRequest 'tools/list', {}, 2, (err, res) ->
    if err
      console.error '   ❌ Error:', err.message
      return
    
    if res.error
      console.error '   ❌ JSON-RPC Error:', res.error
      return
    
    console.log '   ✅ Listed tools successfully'
    console.log '   Available tools:'
    for tool in res.result?.tools or []
      console.log "     - #{tool.name}: #{tool.description}"
    
    # Test 3: Get current time
    console.log '\n3. Testing tools/call (getTime)...'
    makeRequest 'tools/call',
      name: 'clodforest.getTime'
      arguments:
        format: 'iso8601'
    , 3, (err, res) ->
      if err
        console.error '   ❌ Error:', err.message
        return
      
      if res.error
        console.error '   ❌ JSON-RPC Error:', res.error
        return
      
      console.log '   ✅ Called tool successfully'
      console.log '   Current time:', res.result?.content?[0]?.text
      
      # Test 4: List resources
      console.log '\n4. Testing resources/list...'
      makeRequest 'resources/list', {}, 4, (err, res) ->
        if err
          console.error '   ❌ Error:', err.message
          return
        
        if res.error
          console.error '   ❌ JSON-RPC Error:', res.error
          return
        
        console.log '   ✅ Listed resources successfully'
        console.log '   Sample resources:'
        for resource, i in res.result?.resources or [] when i < 5
          console.log "     - #{resource.uri}: #{resource.name}"
        if res.result?.resources?.length > 5
          console.log "     ... and #{res.result.resources.length - 5} more"
        
        # Test 5: Get a resource
        console.log '\n5. Testing resources/get (info)...'
        makeRequest 'resources/get',
          uri: 'clodforest://info'
        , 5, (err, res) ->
          if err
            console.error '   ❌ Error:', err.message
            return
          
          if res.error
            console.error '   ❌ JSON-RPC Error:', res.error
            return
          
          console.log '   ✅ Retrieved resource successfully'
          try
            info = JSON.parse(res.result?.contents?[0]?.text or '{}')
            console.log '   Service:', info.service
            console.log '   Version:', info.version
          catch
            console.log '   Content:', res.result?.contents?[0]?.text?.substring(0, 100) + '...'
          
          # Test 6: List prompts
          console.log '\n6. Testing prompts/list...'
          makeRequest 'prompts/list', {}, 6, (err, res) ->
            if err
              console.error '   ❌ Error:', err.message
              return
            
            if res.error
              console.error '   ❌ JSON-RPC Error:', res.error
              return
            
            console.log '   ✅ Listed prompts successfully'
            console.log '   Available prompts:'
            for prompt in res.result?.prompts or []
              console.log "     - #{prompt.name}: #{prompt.description}"
            
            console.log '\n✨ All tests completed!'

# Handle process errors
process.on 'uncaughtException', (err) ->
  console.error '\n💥 Uncaught exception:', err.message
  process.exit 1
