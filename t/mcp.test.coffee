# FILENAME: { ClodForest/t/mcp.test.coffee }
# MCP (Model Context Protocol) Test Suite

kava = require 'kava'
path = require 'path'
fs = require 'fs'

# Import MCP modules
jsonrpc      = require '../src/coordinator/lib/mcp/jsonrpc'
capabilities = require '../src/coordinator/lib/mcp/capabilities'
methods      = require '../src/coordinator/lib/mcp/methods'
resources    = require '../src/coordinator/lib/mcp/resources'
tools        = require '../src/coordinator/lib/mcp/tools'
prompts      = require '../src/coordinator/lib/mcp/prompts'

kava.suite 'MCP Implementation', (suite, test) ->

  # JSON-RPC Tests
  suite 'JSON-RPC Handler', (suite, test) ->
    
    test 'should parse valid JSON-RPC request', (done) ->
      request = JSON.stringify
        jsonrpc: '2.0'
        method: 'test'
        params: {}
        id: 1
      
      jsonrpc.processJsonRpc request, (response) ->
        if response.error?.code is jsonrpc.ERROR_CODES.METHOD_NOT_FOUND
          done()
        else
          done(new Error('Expected method not found error'))
    
    test 'should handle parse errors', (done) ->
      request = 'invalid json'
      
      jsonrpc.processJsonRpc request, (response) ->
        if response.error?.code is jsonrpc.ERROR_CODES.PARSE_ERROR
          done()
        else
          done(new Error('Expected parse error'))
    
    test 'should validate JSON-RPC version', (done) ->
      request = JSON.stringify
        jsonrpc: '1.0'  # Wrong version
        method: 'test'
        id: 1
      
      jsonrpc.processJsonRpc request, (response) ->
        if response.error?.code is jsonrpc.ERROR_CODES.INVALID_REQUEST
          done()
        else
          done(new Error('Expected invalid request error'))
    
    test 'should reject batch requests', (done) ->
      request = JSON.stringify [
        { jsonrpc: '2.0', method: 'test', id: 1 }
        { jsonrpc: '2.0', method: 'test', id: 2 }
      ]
      
      jsonrpc.processJsonRpc request, (response) ->
        if response.error?.message?.includes('Batch requests not supported')
          done()
        else
          done(new Error('Expected batch request rejection'))

  # Capabilities Tests
  suite 'Capabilities', (suite, test) ->
    
    test 'should return valid capabilities', (done) ->
      caps = capabilities.getCapabilities()
      
      unless caps.protocolVersion is '2025-06-18'
        return done(new Error('Invalid protocol version'))
      
      unless caps.serverInfo?.name is 'clodforest-mcp'
        return done(new Error('Invalid server info'))
      
      unless caps.capabilities?.resources?
        return done(new Error('Missing resources capability'))
      
      unless caps.capabilities?.tools?
        return done(new Error('Missing tools capability'))
      
      unless caps.capabilities?.prompts?
        return done(new Error('Missing prompts capability'))
      
      done()

  # Method Tests
  suite 'MCP Methods', (suite, test) ->
    
    test 'should initialize session', (done) ->
      params =
        clientInfo:
          name: 'test-client'
          version: '1.0.0'
      
      methods.initialize params, (error, result) ->
        if error
          return done(error)
        
        unless result.protocolVersion
          return done(new Error('Missing protocol version'))
        
        unless result.serverInfo
          return done(new Error('Missing server info'))
        
        done()
    
    test 'should require initialization for resources/list', (done) ->
      # Create a fresh methods module to test uninitialized state
      # We need to clear the require cache to get a fresh module
      delete require.cache[require.resolve('../src/coordinator/lib/mcp/methods')]
      freshMethods = require '../src/coordinator/lib/mcp/methods'
      
      freshMethods['resources/list'] {}, (error, result) ->
        if error?.code is -32002 and error.message is 'Not initialized'
          done()
        else
          done(new Error('Expected not initialized error'))
    
    test 'should require uri parameter for resources/get', (done) ->
      # Initialize first
      methods.initialize {}, ->
        methods['resources/get'] {}, (error, result) ->
          if error?.code is -32602
            done()
          else
            done(new Error('Expected invalid params error'))

  # Resources Tests
  suite 'MCP Resources', (suite, test) ->
    
    test 'should list available resources', (done) ->
      resources.listResources (error, resourceList) ->
        if error
          return done(error)
        
        unless Array.isArray(resourceList)
          return done(new Error('Resources should be an array'))
        
        # Should include special resources
        hasInfo = resourceList.some (r) -> r.uri is 'clodforest://info'
        hasHealth = resourceList.some (r) -> r.uri is 'clodforest://health'
        
        unless hasInfo
          return done(new Error('Missing info resource'))
        
        unless hasHealth
          return done(new Error('Missing health resource'))
        
        done()
    
    test 'should get info resource', (done) ->
      resources.getResource 'clodforest://info', (error, resource) ->
        if error
          return done(error)
        
        unless resource.uri is 'clodforest://info'
          return done(new Error('Invalid resource URI'))
        
        unless resource.mimeType is 'application/json'
          return done(new Error('Invalid mime type'))
        
        unless resource.contents?[0]?.text
          return done(new Error('Missing resource content'))
        
        # Parse and validate content
        try
          info = JSON.parse(resource.contents[0].text)
          unless info.service and info.version
            return done(new Error('Invalid info content'))
        catch e
          return done(new Error('Invalid JSON in info resource'))
        
        done()
    
    test 'should get health resource', (done) ->
      resources.getResource 'clodforest://health', (error, resource) ->
        if error
          return done(error)
        
        unless resource.uri is 'clodforest://health'
          return done(new Error('Invalid resource URI'))
        
        # Parse and validate content
        try
          health = JSON.parse(resource.contents[0].text)
          unless health.status is 'healthy'
            return done(new Error('Invalid health status'))
        catch e
          return done(new Error('Invalid JSON in health resource'))
        
        done()
    
    test 'should reject invalid resource URI', (done) ->
      resources.getResource 'invalid://uri', (error, resource) ->
        if error?.code is -32602
          done()
        else
          done(new Error('Expected invalid params error'))

  # Tools Tests
  suite 'MCP Tools', (suite, test) ->
    
    test 'should list available tools', (done) ->
      tools.listTools (error, toolList) ->
        if error
          return done(error)
        
        unless Array.isArray(toolList)
          return done(new Error('Tools should be an array'))
        
        # Check for expected tools
        toolNames = toolList.map (t) -> t.name
        expectedTools = [
          'clodforest.getTime'
          'clodforest.checkHealth'
          'clodforest.listRepositories'
          'clodforest.browseRepository'
          'clodforest.readFile'
        ]
        
        for expectedTool in expectedTools
          unless expectedTool in toolNames
            return done(new Error("Missing expected tool: #{expectedTool}"))
        
        done()
    
    test 'should call getTime tool', (done) ->
      tools.callTool 'clodforest.getTime', { format: 'iso8601' }, (error, result) ->
        if error
          return done(error)
        
        unless result.content?[0]?.text
          return done(new Error('Missing tool result'))
        
        # Validate ISO8601 format
        timestamp = result.content[0].text
        unless timestamp.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
          return done(new Error('Invalid timestamp format'))
        
        done()
    
    test 'should call checkHealth tool', (done) ->
      tools.callTool 'clodforest.checkHealth', {}, (error, result) ->
        if error
          return done(error)
        
        # Parse and validate health data
        try
          health = JSON.parse(result.content[0].text)
          unless health.status is 'healthy'
            return done(new Error('Invalid health status'))
        catch e
          return done(new Error('Invalid JSON in health result'))
        
        done()
    
    test 'should validate required parameters', (done) ->
      tools.callTool 'clodforest.readFile', {}, (error, result) ->
        if error?.code is -32602
          done()
        else
          done(new Error('Expected invalid params error'))
    
    test 'should handle unknown tool', (done) ->
      tools.callTool 'unknown.tool', {}, (error, result) ->
        if error?.code is -32601
          done()
        else
          done(new Error('Expected method not found error'))

  # Prompts Tests
  suite 'MCP Prompts', (suite, test) ->
    
    test 'should list available prompts', (done) ->
      prompts.listPrompts (error, promptList) ->
        if error
          return done(error)
        
        unless Array.isArray(promptList)
          return done(new Error('Prompts should be an array'))
        
        # Check for expected prompts
        promptNames = promptList.map (p) -> p.name
        expectedPrompts = ['load_context', 'session_handoff', 'explore_repository']
        
        for expectedPrompt in expectedPrompts
          unless expectedPrompt in promptNames
            return done(new Error("Missing expected prompt: #{expectedPrompt}"))
        
        done()
    
    test 'should get load_context prompt', (done) ->
      args =
        context_path: 'core/test.yaml'
      
      prompts.getPrompt 'load_context', args, (error, prompt) ->
        if error
          return done(error)
        
        unless prompt.messages?[0]?.content?.text
          return done(new Error('Missing prompt messages'))
        
        # Check that context path is included
        unless prompt.messages[0].content.text.includes(args.context_path)
          return done(new Error('Context path not included in prompt'))
        
        done()
    
    test 'should validate required prompt arguments', (done) ->
      prompts.getPrompt 'load_context', {}, (error, prompt) ->
        if error?.code is -32602
          done()
        else
          done(new Error('Expected invalid params error'))
    
    test 'should handle unknown prompt', (done) ->
      prompts.getPrompt 'unknown_prompt', {}, (error, prompt) ->
        if error?.code is -32602
          done()
        else
          done(new Error('Expected invalid params error'))

  # Integration Tests
  suite 'MCP Integration', (suite, test) ->
    
    test 'should handle full initialize -> list -> get flow', (done) ->
      # Step 1: Initialize
      initRequest = JSON.stringify
        jsonrpc: '2.0'
        method: 'initialize'
        params: { clientInfo: { name: 'test', version: '1.0' } }
        id: 1
      
      jsonrpc.processJsonRpc initRequest, (initResponse) ->
        unless initResponse.result?.protocolVersion
          return done(new Error('Initialize failed'))
        
        # Step 2: List resources
        listRequest = JSON.stringify
          jsonrpc: '2.0'
          method: 'resources/list'
          params: {}
          id: 2
        
        jsonrpc.processJsonRpc listRequest, (listResponse) ->
          unless listResponse.result?.resources
            return done(new Error('List resources failed'))
          
          # Step 3: Get a resource
          getRequest = JSON.stringify
            jsonrpc: '2.0'
            method: 'resources/get'
            params: { uri: 'clodforest://info' }
            id: 3
          
          jsonrpc.processJsonRpc getRequest, (getResponse) ->
            unless getResponse.result?.contents
              return done(new Error('Get resource failed'))
            
            done()
    
    test 'should handle notifications without response', (done) ->
      # Initialize first
      methods.initialize {}, ->
        # Send notification (no id)
        notificationRequest = JSON.stringify
          jsonrpc: '2.0'
          method: 'notifications/initialized'
          params: {}
        
        jsonrpc.processJsonRpc notificationRequest, (response) ->
          if response is null
            done()
          else
            done(new Error('Notification should not return response'))

# Add to main test index
module.exports = true  # Mark as loaded
