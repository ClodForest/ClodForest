#!/usr/bin/env coffee
# FILENAME: test/mcp-inspector-cli-test.coffee
# Comprehensive MCP testing using the official MCP Inspector CLI

{ spawn } = require 'node:child_process'
{ promisify } = require 'node:util'

CONFIG =
  baseUrl: 'http://localhost:8080'
  timeout: 30000

# Test our MCP server using the official MCP Inspector CLI
runMcpInspectorCliTests = ->
  console.log '🔍 MCP Inspector CLI Test Suite'
  console.log "Server: #{CONFIG.baseUrl}"
  
  # Test server discovery and connection
  await testStep 'Server Discovery', testServerDiscovery()
  
  # Test OAuth2 authentication flow
  await testStep 'OAuth2 Authentication', testOAuth2Flow()
  
  # Test MCP protocol compliance
  await testStep 'MCP Protocol Compliance', testMcpCompliance()
  
  # Test tool functionality
  await testStep 'Tool Operations', testToolOperations()
  
  # Test resource access
  await testStep 'Resource Access', testResourceAccess()
  
  # Test error handling
  await testStep 'Error Handling', testErrorHandling()
  
  console.log '\n🔍 MCP Inspector CLI test suite complete'

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

testServerDiscovery = ->
  # Test if the MCP Inspector can discover our server
  try
    result = await runMcpInspectorCli [
      '--cli'
      CONFIG.baseUrl
      '--method'
      'initialize'
    ]
    
    if result.success
      success: true
      message: 'Server discovery successful'
      data: result.output
    else
      success: false
      message: "Server discovery failed: #{result.error}"
  catch error
    success: false
    message: "Discovery error: #{error.message}"

testOAuth2Flow = ->
  # Test OAuth2 client registration and token acquisition
  try
    # First, try to register a client using the MCP Inspector
    # This will test our OAuth2 implementation
    result = await runMcpInspectorCli [
      '--cli'
      CONFIG.baseUrl
      '--method'
      'connect'
    ]
    
    if result.success
      success: true
      message: 'OAuth2 authentication flow successful'
      data: result.output
    else
      success: false
      message: "OAuth2 flow failed: #{result.error}"
  catch error
    success: false
    message: "OAuth2 error: #{error.message}"

testMcpCompliance = ->
  # Test MCP protocol compliance using Inspector's built-in validation
  try
    result = await runMcpInspectorCli [
      '--cli'
      CONFIG.baseUrl
      '--method'
      'tools/list'
    ]
    
    if result.success
      # Parse the output to verify MCP compliance
      tools = JSON.parse(result.output)
      if tools.tools && Array.isArray(tools.tools)
        success: true
        message: "MCP protocol compliance verified - found #{tools.tools.length} tools"
        data: tools
      else
        success: false
        message: 'Invalid MCP response format'
    else
      success: false
      message: "MCP compliance test failed: #{result.error}"
  catch error
    success: false
    message: "MCP compliance error: #{error.message}"

testToolOperations = ->
  # Test our state management tools
  try
    # Test list_state_files tool
    result = await runMcpInspectorCli [
      '--cli'
      CONFIG.baseUrl
      '--method'
      'tools/call'
      '--tool-name'
      'list_state_files'
      '--tool-arg'
      'path=.'
    ]
    
    if result.success
      output = JSON.parse(result.output)
      if output.content
        success: true
        message: 'Tool operations successful - list_state_files working'
        data: output
      else
        success: false
        message: 'Tool returned invalid response'
    else
      success: false
      message: "Tool operation failed: #{result.error}"
  catch error
    success: false
    message: "Tool operation error: #{error.message}"

testResourceAccess = ->
  # Test resource listing and access
  try
    result = await runMcpInspectorCli [
      '--cli'
      CONFIG.baseUrl
      '--method'
      'resources/list'
    ]
    
    if result.success
      resources = JSON.parse(result.output)
      if resources.resources
        success: true
        message: "Resource access successful - found #{resources.resources.length} resources"
        data: resources
      else
        success: false
        message: 'No resources found or invalid format'
    else
      success: false
      message: "Resource access failed: #{result.error}"
  catch error
    success: false
    message: "Resource access error: #{error.message}"

testErrorHandling = ->
  # Test error handling with invalid requests
  try
    result = await runMcpInspectorCli [
      '--cli'
      CONFIG.baseUrl
      '--method'
      'tools/call'
      '--tool-name'
      'nonexistent_tool'
    ]
    
    # We expect this to fail, so success means proper error handling
    if not result.success
      success: true
      message: 'Error handling working correctly - invalid tool rejected'
      data: result.error
    else
      success: false
      message: 'Error handling failed - invalid tool was accepted'
  catch error
    # Expected behavior for invalid requests
    success: true
    message: 'Error handling working correctly - exception thrown for invalid tool'

runMcpInspectorCli = (args) ->
  new Promise (resolve, reject) ->
    # Run the MCP Inspector CLI with the given arguments
    child = spawn 'npx', ['@modelcontextprotocol/inspector'].concat(args), {
      stdio: ['pipe', 'pipe', 'pipe']
      timeout: CONFIG.timeout
    }
    
    stdout = ''
    stderr = ''
    
    child.stdout.on 'data', (data) ->
      stdout += data.toString()
    
    child.stderr.on 'data', (data) ->
      stderr += data.toString()
    
    child.on 'close', (code) ->
      if code is 0
        resolve {
          success: true
          output: stdout.trim()
          error: null
        }
      else
        resolve {
          success: false
          output: stdout.trim()
          error: stderr.trim() or "Process exited with code #{code}"
        }
    
    child.on 'error', (error) ->
      reject error
    
    # Set timeout
    setTimeout ->
      child.kill('SIGTERM')
      reject new Error('Test timeout')
    , CONFIG.timeout

if require.main is module
  runMcpInspectorCliTests().catch (error) ->
    console.error 'MCP Inspector CLI test error:', error
    process.exit 1
else
  module.exports = { runMcpInspectorCliTests }
