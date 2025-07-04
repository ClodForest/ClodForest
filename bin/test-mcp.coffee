#!/usr/bin/env coffee
# ClodForest MCP Server Test Script
# Supports testing both local development and production environments

http = require 'http'
https = require 'https'

# Parse command line arguments
args = process.argv.slice(2)

# Default configuration (local development)
config =
  host: 'localhost'
  port: 8080
  path: '/api/mcp'
  useHttps: false
  environment: 'local'

# Environment presets
environments =
  local:
    host: 'localhost'
    port: 8080
    path: '/api/mcp'
    useHttps: false
    environment: 'local'
  
  production:
    host: 'clodforest.thatsnice.org'
    port: 443
    path: '/api/mcp'
    useHttps: true
    environment: 'production'

# Parse arguments
showHelp = ->
  console.log '''
    ClodForest MCP Server Test Script
    
    Usage:
      coffee bin/test-mcp.coffee [options]
    
    Options:
      --env, -e <environment>    Environment preset (local, production)
      --host, -h <hostname>      Server hostname
      --port, -p <port>          Server port
      --https                    Use HTTPS
      --http                     Use HTTP
      --help                     Show this help
    
    Environment Presets:
      local                      http://localhost:8080/api/mcp (default)
      production                 https://clodforest.thatsnice.org:443/api/mcp
    
    Examples:
      coffee bin/test-mcp.coffee                           # Test local development
      coffee bin/test-mcp.coffee --env production          # Test production
      coffee bin/test-mcp.coffee --host example.com --port 3000 --https
    '''
  process.exit 0

i = 0
while i < args.length
  arg = args[i]
  
  switch arg
    when '--help'
      showHelp()
    
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

# Configuration
HOST = config.host
PORT = config.port
PATH = config.path
USE_HTTPS = config.useHttps

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
protocol = if USE_HTTPS then 'https' else 'http'
console.log "🌐 Testing ClodForest MCP Server (#{config.environment})"
console.log "   Target: #{protocol}://#{HOST}:#{PORT}#{PATH}\n"

# Test 1: Initialize
console.log '1. Testing initialize...'
makeRequest 'initialize', 
  clientInfo:
    name: "mcp-test-client-#{config.environment}"
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
                
                console.log "\n🎉 MCP testing complete (#{config.environment})!"
                console.log '\n📊 Test Summary:'
                console.log '   ✅ MCP Protocol: Working'
                console.log '   ✅ Context Operations: Working'
                console.log '   ✅ Repository Operations: Working'
                console.log '   ✅ Health & Time: Working'
                console.log '   ✅ Search Intelligence: Working'
                console.log "\n🚀 ClodForest MCP Server (#{config.environment}) is fully operational!"

# Handle process errors
process.on 'uncaughtException', (err) ->
  console.error '\n💥 Uncaught exception:', err.message
  process.exit 1
