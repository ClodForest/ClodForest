# FILENAME: { ClodForest/src/coordinator/lib/mcp/resources.coffee }
# MCP Resources Implementation
# Expose ClodForest data as MCP resources

fs     = require 'fs'
path   = require 'path'
config = require '../config'

# List all available resources
listResources = (callback) ->
  resources = []
  
  # Repository files as resources
  try
    # List repositories
    repos = fs.readdirSync(config.REPO_PATH)
      .filter (item) ->
        itemPath = path.join(config.REPO_PATH, item)
        fs.statSync(itemPath).isDirectory()
    
    # Add context files as resources
    for repo in repos
      # Special handling for state repository contexts
      if repo is 'contexts'
        contextsPath = path.join(config.REPO_PATH, repo)
        addContextResources contextsPath, '', resources
    
    # Add repository info resource
    resources.push
      uri:         'clodforest://info'
      name:        'ClodForest Information'
      description: 'General information about the ClodForest service'
      mimeType:    'application/json'
    
    # Add health status resource  
    resources.push
      uri:         'clodforest://health'
      name:        'Service Health'
      description: 'Current health status of ClodForest service'
      mimeType:    'application/json'
    
    callback null, resources
    
  catch error
    callback
      code: -32603
      message: 'Failed to list resources'
      data: error.message

# Add context files as resources recursively
addContextResources = (basePath, relativePath, resources) ->
  fullPath = path.join(basePath, relativePath)
  
  try
    items = fs.readdirSync(fullPath)
    
    for item in items
      itemPath = path.join(fullPath, item)
      itemRelative = if relativePath then "#{relativePath}/#{item}" else item
      stat = fs.statSync(itemPath)
      
      if stat.isDirectory()
        # Recurse into subdirectories
        addContextResources basePath, itemRelative, resources
      else if item.endsWith('.yaml') or item.endsWith('.md')
        # Add YAML and Markdown files as resources
        resources.push
          uri:         "clodforest://contexts/#{itemRelative}"
          name:        item
          description: "Context file: #{itemRelative}"
          mimeType:    if item.endsWith('.yaml') then 'application/yaml' else 'text/markdown'
  
  catch error
    console.error "Error scanning #{fullPath}:", error.message

# Get a specific resource by URI
getResource = (uri, callback) ->
  unless uri.startsWith('clodforest://')
    return callback
      code: -32602
      message: 'Invalid resource URI'
  
  resourcePath = uri.substring('clodforest://'.length)
  
  # Handle special resources
  switch resourcePath
    when 'info'
      callback null,
        uri: uri
        mimeType: 'application/json'
        contents: [
          type: 'text'
          text: JSON.stringify({
            service:     config.SERVICE_NAME
            version:     config.VERSION
            description: 'Coordination service for distributed Claude instances'
            repository:  config.REPO_PATH
            environment: config.getEnvironmentInfo()
          }, null, 2)
        ]
    
    when 'health'
      uptime   = process.uptime()
      memUsage = process.memoryUsage()
      
      callback null,
        uri: uri
        mimeType: 'application/json'
        contents: [
          type: 'text'
          text: JSON.stringify({
            status:    'healthy'
            timestamp: new Date().toISOString()
            uptime:    "#{Math.floor(uptime)} seconds"
            memory:
              rss:       "#{Math.round(memUsage.rss / 1024 / 1024)} MB"
              heapUsed:  "#{Math.round(memUsage.heapUsed / 1024 / 1024)} MB"
              heapTotal: "#{Math.round(memUsage.heapTotal / 1024 / 1024)} MB"
          }, null, 2)
        ]
    
    else
      # Try to read from filesystem
      if resourcePath.startsWith('contexts/')
        filePath = path.join(config.REPO_PATH, resourcePath.substring('contexts/'.length))
        
        try
          content = fs.readFileSync(filePath, 'utf8')
          mimeType = if filePath.endsWith('.yaml') then 'application/yaml' else 'text/markdown'
          
          callback null,
            uri: uri
            mimeType: mimeType
            contents: [
              type: 'text'
              text: content
            ]
        
        catch error
          callback
            code: -32603
            message: 'Resource not found'
            data: error.message
      
      else
        callback
          code: -32602
          message: 'Unknown resource URI'

module.exports = {
  listResources
  getResource
}
