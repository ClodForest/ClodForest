# FILENAME: { ClodForest/src/coordinator/lib/mcp/methods.coffee }
# MCP Method Implementations
# All JSON-RPC methods supported by this MCP server

capabilities = require './capabilities'
resources    = require './resources'
tools        = require './tools'
prompts      = require './prompts'

# Session state
session =
  initialized: false
  clientInfo: null

# Core Methods

# Initialize the connection
initialize = (params, callback) ->
  # Store client info
  session.clientInfo = params.clientInfo if params.clientInfo
  
  # Get our capabilities
  caps = capabilities.getCapabilities()
  
  # Mark as initialized
  session.initialized = true
  
  callback null, caps

# Handle initialized notification
notificationsInitialized = (params, callback) ->
  # This is a notification, no response needed
  console.log 'MCP session initialized'
  callback null, null

# Resource Methods

# List available resources
resourcesList = (params, callback) ->
  unless session.initialized
    return callback
      code: -32002
      message: 'Not initialized'
  
  resources.listResources (error, resourceList) ->
    if error
      callback error
    else
      callback null, resources: resourceList

# Get a specific resource
resourcesGet = (params, callback) ->
  unless session.initialized
    return callback
      code: -32002
      message: 'Not initialized'
  
  unless params.uri
    return callback
      code: -32602
      message: 'Missing required parameter: uri'
  
  resources.getResource params.uri, (error, resource) ->
    if error
      callback error
    else
      callback null, contents: resource.contents

# Tool Methods

# List available tools
toolsList = (params, callback) ->
  unless session.initialized
    return callback
      code: -32002
      message: 'Not initialized'
  
  tools.listTools (error, toolList) ->
    if error
      callback error
    else
      callback null, tools: toolList

# Call a tool
toolsCall = (params, callback) ->
  unless session.initialized
    return callback
      code: -32002
      message: 'Not initialized'
  
  unless params.name
    return callback
      code: -32602
      message: 'Missing required parameter: name'
  
  tools.callTool params.name, params.arguments or {}, (error, result) ->
    if error
      callback error
    else
      callback null, content: result.content

# Prompt Methods

# List available prompts
promptsList = (params, callback) ->
  unless session.initialized
    return callback
      code: -32002
      message: 'Not initialized'
  
  prompts.listPrompts (error, promptList) ->
    if error
      callback error
    else
      callback null, prompts: promptList

# Get a specific prompt
promptsGet = (params, callback) ->
  unless session.initialized
    return callback
      code: -32002
      message: 'Not initialized'
  
  unless params.name
    return callback
      code: -32602
      message: 'Missing required parameter: name'
  
  prompts.getPrompt params.name, params.arguments or {}, (error, prompt) ->
    if error
      callback error
    else
      callback null, messages: prompt.messages

# Export all methods
module.exports =
  # Core
  'initialize':              initialize
  'notifications/initialized': notificationsInitialized
  
  # Resources
  'resources/list': resourcesList
  'resources/get':  resourcesGet
  
  # Tools
  'tools/list': toolsList
  'tools/call': toolsCall
  
  # Prompts
  'prompts/list': promptsList
  'prompts/get':  promptsGet
