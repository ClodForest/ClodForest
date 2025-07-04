#!/usr/bin/env coffee
# Test ClodForest MCP Server on production (clodforest.thatsnice.org:8080)

http = require 'http'
https = require 'https'

# Production Configuration
HOST = 'clodforest.thatsnice.org'
PORT = 443
PATH = '/api/mcp'
USE_HTTPS = true  # Production uses HTTPS

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
  
  httpModule = if USE_HTTPS then https else http
  
  req = httpModule.request options, (res) ->
    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      try
        response = JSON.parse(data)
        callback null, response
      catch e
        callback new Error("Parse error: #{data}")
  
  req.on 'error', callback
  req.write requestData
  req.end()

# Test sequence
console.log "🌐 Testing ClodForest MCP Server on #{HOST}:#{PORT}...\n"

# Test 1: Initialize
console.log '1. Testing initialize...'
makeRequest 'initialize', 
  clientInfo:
    name: 'production-test-client'
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
  console.log '   Version:', res.result?.serverInfo?.version
  
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
    console.log "   Total tools: #{res.result?.tools?.length or 0}"
    console.log '   Available tools:'
    for tool in res.result?.tools or []
      console.log "     - #{tool.name}: #{tool.description}"
    
    # Test 3: Test context listing (ClodForest's unique feature)
    console.log '\n3. Testing context operations (listContexts)...'
    makeRequest 'tools/call',
      name: 'clodforest.listContexts'
      arguments: {}
    , 3, (err, res) ->
      if err
        console.error '   ❌ Error:', err.message
        return
      
      if res.error
        console.error '   ❌ JSON-RPC Error:', res.error
        return
      
      console.log '   ✅ Listed contexts successfully'
      contextText = res.result?.content?[0]?.text or ''
      lines = contextText.split('\n').filter((line) -> line.trim().startsWith('-'))
      console.log "   Found #{lines.length} contexts"
      console.log '   Sample contexts:'
      for line, i in lines when i < 5
        console.log "     #{line.trim()}"
      if lines.length > 5
        console.log "     ... and #{lines.length - 5} more"
      
      # Test 4: Get a specific context
      console.log '\n4. Testing getContext (robert_identity)...'
      makeRequest 'tools/call',
        name: 'clodforest.getContext'
        arguments:
          name: 'robert_identity'
          resolveInheritance: true
      , 4, (err, res) ->
        if err
          console.error '   ❌ Error:', err.message
          return
        
        if res.error
          console.error '   ❌ JSON-RPC Error:', res.error
          return
        
        console.log '   ✅ Retrieved context successfully'
        contextContent = res.result?.content?[0]?.text or ''
        console.log "   Context length: #{contextContent.length} characters"
        console.log '   Content preview:'
        preview = contextContent.substring(0, 200).replace(/\n/g, ' ')
        console.log "     #{preview}..."
        
        # Test 5: Search contexts
        console.log '\n5. Testing searchContexts...'
        makeRequest 'tools/call',
          name: 'clodforest.searchContexts'
          arguments:
            query: 'collaboration'
            limit: 3
            includeContent: true
        , 5, (err, res) ->
          if err
            console.error '   ❌ Error:', err.message
            return
          
          if res.error
            console.error '   ❌ JSON-RPC Error:', res.error
            return
          
          console.log '   ✅ Search completed successfully'
          searchResults = res.result?.content?[0]?.text or ''
          resultLines = searchResults.split('\n').filter((line) -> line.startsWith('## '))
          console.log "   Found #{resultLines.length} matching contexts"
          for line in resultLines
            console.log "     #{line.replace('## ', '- ')}"
          
          # Test 6: Check health
          console.log '\n6. Testing health check...'
          makeRequest 'tools/call',
            name: 'clodforest.checkHealth'
            arguments: {}
          , 6, (err, res) ->
            if err
              console.error '   ❌ Error:', err.message
              return
            
            if res.error
              console.error '   ❌ JSON-RPC Error:', res.error
              return
            
            console.log '   ✅ Health check successful'
            try
              healthData = JSON.parse(res.result?.content?[0]?.text or '{}')
              console.log '   Status:', healthData.status
              console.log '   Uptime:', healthData.uptime
              console.log '   Memory (RSS):', healthData.memory?.rss
            catch
              console.log '   Health data received'
            
            # Test 7: Get current time
            console.log '\n7. Testing getTime...'
            makeRequest 'tools/call',
              name: 'clodforest.getTime'
              arguments:
                format: 'iso8601'
            , 7, (err, res) ->
              if err
                console.error '   ❌ Error:', err.message
                return
              
              if res.error
                console.error '   ❌ JSON-RPC Error:', res.error
                return
              
              console.log '   ✅ Time retrieved successfully'
              console.log '   Server time:', res.result?.content?[0]?.text
              
              # Test 8: List repositories
              console.log '\n8. Testing listRepositories...'
              makeRequest 'tools/call',
                name: 'clodforest.listRepositories'
                arguments: {}
              , 8, (err, res) ->
                if err
                  console.error '   ❌ Error:', err.message
                  return
                
                if res.error
                  console.error '   ❌ JSON-RPC Error:', res.error
                  return
                
                console.log '   ✅ Repositories listed successfully'
                try
                  repoData = JSON.parse(res.result?.content?[0]?.text or '{}')
                  console.log "   Found #{repoData.count or 0} repositories"
                  if repoData.repositories
                    for repo, i in repoData.repositories when i < 3
                      console.log "     - #{repo}"
                    if repoData.repositories.length > 3
                      console.log "     ... and #{repoData.repositories.length - 3} more"
                catch
                  console.log '   Repository data received'
                
                console.log '\n🎉 Production MCP testing complete!'
                console.log '\n📊 Test Summary:'
                console.log '   ✅ MCP Protocol: Working'
                console.log '   ✅ Context Operations: Working'
                console.log '   ✅ Repository Operations: Working'
                console.log '   ✅ Health & Time: Working'
                console.log '   ✅ Search Intelligence: Working'
                console.log '\n🚀 ClodForest MCP Server is fully operational!'

# Handle process errors
process.on 'uncaughtException', (err) ->
  console.error '\n💥 Uncaught exception:', err.message
  process.exit 1
