# FILENAME: { ClodForest/src/coordinator/lib/mcp/tools.coffee }
# MCP Tools Implementation
# Expose ClodForest operations as MCP tools

{exec} = require 'child_process'
config = require '../config'
apis   = require '../apis'

# Tool definitions
TOOLS = [
  {
    name: 'clodforest.getTime'
    description: 'Get current time information from ClodForest'
    inputSchema:
      type: 'object'
      properties:
        format:
          type: 'string'
          description: 'Time format: iso8601, unix, rfc2822, milliseconds'
          enum: ['iso8601', 'unix', 'rfc2822', 'milliseconds']
          default: 'iso8601'
  }
  
  {
    name: 'clodforest.checkHealth'
    description: 'Check the health status of ClodForest service'
    inputSchema:
      type: 'object'
      properties: {}
  }
  
  {
    name: 'clodforest.listRepositories'
    description: 'List all available repositories in ClodForest'
    inputSchema:
      type: 'object'
      properties: {}
  }
  
  {
    name: 'clodforest.browseRepository'
    description: 'Browse contents of a specific repository'
    inputSchema:
      type: 'object'
      properties:
        repository:
          type: 'string'
          description: 'Repository name to browse'
        path:
          type: 'string'
          description: 'Path within repository (optional)'
      required: ['repository']
  }
  
  {
    name: 'clodforest.readFile'
    description: 'Read a file from a repository'
    inputSchema:
      type: 'object'
      properties:
        repository:
          type: 'string'
          description: 'Repository name'
        path:
          type: 'string'
          description: 'File path within repository'
      required: ['repository', 'path']
  }
]

# Add git tools if enabled
if config.FEATURES.GIT_OPERATIONS
  TOOLS.push
    name: 'clodforest.gitStatus'
    description: 'Get git status for a repository'
    inputSchema:
      type: 'object'
      properties:
        repository:
          type: 'string'
          description: 'Repository name'
      required: ['repository']

# List available tools
listTools = (callback) ->
  callback null, TOOLS

# Execute a tool
callTool = (toolName, args, callback) ->
  switch toolName
    when 'clodforest.getTime'
      # Create a mock request object for getTimeData
      mockReq = 
        get: (header) -> null  # Return null for any header request
      
      timeData = apis.getTimeData(mockReq)
      format = args.format or 'iso8601'
      
      result = switch format
        when 'unix'         then timeData.formats.unix.toString()
        when 'rfc2822'      then timeData.formats.rfc2822
        when 'milliseconds' then timeData.formats.milliseconds.toString()
        else timeData.timestamp
      
      callback null,
        content: [
          type: 'text'
          text: result
        ]
    
    when 'clodforest.checkHealth'
      healthData = apis.getHealthData()
      
      callback null,
        content: [
          type: 'text'
          text: JSON.stringify(healthData, null, 2)
        ]
    
    when 'clodforest.listRepositories'
      repoData = apis.getRepositoryData()
      
      callback null,
        content: [
          type: 'text'
          text: JSON.stringify(repoData, null, 2)
        ]
    
    when 'clodforest.browseRepository'
      unless args.repository
        return callback
          code: -32602
          message: 'Missing required parameter: repository'
      
      browseData = apis.browseRepository(args.repository, args.path or '')
      
      if browseData.error
        callback
          code: -32603
          message: browseData.error
          data: browseData.message
      else
        callback null,
          content: [
            type: 'text'
            text: JSON.stringify(browseData, null, 2)
          ]
    
    when 'clodforest.readFile'
      unless args.repository and args.path
        return callback
          code: -32602
          message: 'Missing required parameters: repository, path'
      
      fileData = apis.readRepositoryFile(args.repository, args.path)
      
      if fileData.error
        callback
          code: -32603
          message: fileData.error
          data: fileData.message
      else
        callback null,
          content: [
            type: 'text'
            text: fileData.content
          ]
    
    when 'clodforest.gitStatus'
      unless args.repository
        return callback
          code: -32602
          message: 'Missing required parameter: repository'
      
      apis.executeGitCommand args.repository, 'status', [], (gitData) ->
        if gitData.error
          callback
            code: -32603
            message: gitData.error
            data: gitData.stderr
        else
          callback null,
            content: [
              type: 'text'
              text: gitData.stdout
            ]
    
    else
      callback
        code: -32601
        message: "Unknown tool: #{toolName}"

module.exports = {
  listTools
  callTool
}
