# FILENAME: { ClodForest/src/coordinator/lib/mcp/tools.coffee }
# MCP Tools Implementation
# Expose ClodForest operations as MCP tools

{exec} = require 'child_process'
fs     = require 'node:fs/promises'
path   = require 'node:path'
yaml   = require 'js-yaml'
config = require '../config'
apis   = require '../apis'
logger = require '../logger'

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

# Context operation tools - ClodForest's core value proposition
TOOLS.push(
  {
    name: 'clodforest.getContext'
    description: 'Retrieve context data by name with inheritance resolution'
    inputSchema:
      type: 'object'
      properties:
        name:
          type: 'string'
          description: 'Context name (e.g., "robert-identity", "collaboration-patterns")'
        resolveInheritance:
          type: 'boolean'
          description: 'Whether to resolve context inheritance chains'
          default: true
      required: ['name']
  }
  
  {
    name: 'clodforest.setContext'
    description: 'Create or update context data'
    inputSchema:
      type: 'object'
      properties:
        name:
          type: 'string'
          description: 'Context name to create/update'
        content:
          type: 'string'
          description: 'Context content (YAML format preferred)'
        inherits:
          type: 'array'
          items: { type: 'string' }
          description: 'List of parent contexts to inherit from'
      required: ['name', 'content']
  }
  
  {
    name: 'clodforest.listContexts'
    description: 'List all available contexts with metadata'
    inputSchema:
      type: 'object'
      properties:
        category:
          type: 'string'
          description: 'Filter by category (core, domains, projects)'
        pattern:
          type: 'string'
          description: 'Filter by name pattern (supports wildcards)'
  }
  
  {
    name: 'clodforest.inheritContext'
    description: 'Create new context that inherits from existing contexts'
    inputSchema:
      type: 'object'
      properties:
        name:
          type: 'string'
          description: 'New context name'
        parents:
          type: 'array'
          items: { type: 'string' }
          description: 'Parent contexts to inherit from'
        content:
          type: 'string'
          description: 'Additional content for this context'
        description:
          type: 'string'
          description: 'Description of this context'
      required: ['name', 'parents']
  }
  
  {
    name: 'clodforest.searchContexts'
    description: 'Search context content and metadata'
    inputSchema:
      type: 'object'
      properties:
        query:
          type: 'string'
          description: 'Search query string'
        limit:
          type: 'number'
          description: 'Maximum number of results'
          default: 10
        includeContent:
          type: 'boolean'
          description: 'Include content excerpts in results'
          default: true
      required: ['query']
  }
)

# List available tools
listTools = (callback) ->
  callback null, TOOLS

# Execute a tool
callTool = (toolName, args, req, callback) ->
  startTime = Date.now()
  
  # Log tool call start
  logger.logMCP req, 'mcp_tool_call',
    tool_name: toolName
    arguments: args
  
  # Wrapper callback to add logging
  loggedCallback = (error, result) ->
    responseTime = Date.now() - startTime
    
    if error
      logger.logMCP req, 'mcp_tool_error',
        tool_name: toolName
        error_code: error.code
        error_message: error.message
        response_time_ms: responseTime
    else
      # Log successful tool execution with result metadata
      resultMetadata = 
        tool_name: toolName
        success: true
        response_time_ms: responseTime
      
      # Add specific metadata for context operations
      if toolName.includes('Context')
        if toolName is 'clodforest.getContext' and args.name
          resultMetadata.context_name = args.name
          resultMetadata.resolve_inheritance = args.resolveInheritance ? true
        else if toolName is 'clodforest.setContext' and args.name
          resultMetadata.context_name = args.name
          resultMetadata.context_operation = 'set'
        else if toolName is 'clodforest.searchContexts' and args.query
          resultMetadata.search_query = args.query
          resultMetadata.search_limit = args.limit ? 10
        else if toolName is 'clodforest.listContexts'
          resultMetadata.context_operation = 'list'
          if args.category
            resultMetadata.filter_category = args.category
      
      logger.logMCP req, 'mcp_tool_success', resultMetadata
    
    callback(error, result)
  
  # Execute the actual tool
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
      
      loggedCallback null,
        content: [
          type: 'text'
          text: result
        ]
        isError: false
    
    when 'clodforest.checkHealth'
      healthData = apis.getHealthData()
      
      loggedCallback null,
        content: [
          type: 'text'
          text: JSON.stringify(healthData, null, 2)
        ]
        isError: false
    
    when 'clodforest.listRepositories'
      repoData = apis.getRepositoryData()
      
      loggedCallback null,
        content: [
          type: 'text'
          text: JSON.stringify(repoData, null, 2)
        ]
        isError: false
    
    when 'clodforest.browseRepository'
      unless args.repository
        return loggedCallback
          code: -32602
          message: 'Missing required parameter: repository'
      
      browseData = apis.browseRepository(args.repository, args.path or '')
      
      if browseData.error
        loggedCallback
          code: -32603
          message: browseData.error
          data: browseData.message
      else
        loggedCallback null,
          content: [
            type: 'text'
            text: JSON.stringify(browseData, null, 2)
          ]
          isError: false
    
    when 'clodforest.readFile'
      unless args.repository and args.path
        return loggedCallback
          code: -32602
          message: 'Missing required parameters: repository, path'
      
      fileData = apis.readRepositoryFile(args.repository, args.path)
      
      if fileData.error
        loggedCallback
          code: -32603
          message: fileData.error
          data: fileData.message
      else
        loggedCallback null,
          content: [
            type: 'text'
            text: fileData.content
          ]
          isError: false
    
    when 'clodforest.gitStatus'
      unless args.repository
        return loggedCallback
          code: -32602
          message: 'Missing required parameter: repository'
      
      apis.executeGitCommand args.repository, 'status', [], (gitData) ->
        if gitData.error
          loggedCallback
            code: -32603
            message: gitData.error
            data: gitData.stderr
        else
          loggedCallback null,
            content: [
              type: 'text'
              text: gitData.stdout
            ]
            isError: false
    
    # Context operation handlers
    when 'clodforest.getContext'
      handleGetContext args, loggedCallback
    
    when 'clodforest.setContext'
      handleSetContext args, loggedCallback
    
    when 'clodforest.listContexts'
      handleListContexts args, loggedCallback
    
    when 'clodforest.inheritContext'
      handleInheritContext args, loggedCallback
    
    when 'clodforest.searchContexts'
      handleSearchContexts args, loggedCallback
    
    else
      loggedCallback
        code: -32601
        message: "Unknown tool: #{toolName}"

# Context operation handlers
handleGetContext = (args, callback) ->
  try
    unless args.name
      return callback
        code: -32602
        message: 'Missing required parameter: name'
    
    # Find context file - check multiple possible locations
    contextPaths = [
      path.join(process.cwd(), 'state', 'contexts', 'core', "#{args.name}.yaml")
      path.join(process.cwd(), 'state', 'contexts', 'domains', "#{args.name}.yaml")
      path.join(process.cwd(), 'state', 'contexts', 'projects', "#{args.name}.yaml")
      path.join(process.cwd(), 'state', 'contexts', "#{args.name}.yaml")
    ]
    
    findContextFile = (paths) ->
      for contextPath in paths
        try
          await fs.access(contextPath)
          return contextPath
        catch
          continue
      return null
    
    findContextFile(contextPaths).then (contextPath) ->
      unless contextPath
        return callback
          code: -32603
          message: "Context '#{args.name}' not found"
      
      fs.readFile(contextPath, 'utf8').then (contextContent) ->
        # If inheritance resolution is enabled, process parent contexts
        if args.resolveInheritance ? true
          try
            contextData = yaml.load(contextContent)
            
            if contextData?.inherits?
              inheritedContent = []
              for parent in contextData.inherits
                parentPaths = [
                  path.join(process.cwd(), 'state', 'contexts', 'core', "#{parent}.yaml")
                  path.join(process.cwd(), 'state', 'contexts', 'domains', "#{parent}.yaml")
                  path.join(process.cwd(), 'state', 'contexts', 'projects', "#{parent}.yaml")
                  path.join(process.cwd(), 'state', 'contexts', "#{parent}.yaml")
                ]
                
                parentPath = await findContextFile(parentPaths)
                if parentPath
                  parentContent = await fs.readFile(parentPath, 'utf8')
                  inheritedContent.push("# Inherited from #{parent}\n#{parentContent}")
              
              if inheritedContent.length > 0
                contextContent = inheritedContent.join('\n\n---\n\n') + '\n\n---\n\n' + contextContent
          catch error
            # If YAML parsing fails, just use raw content
            console.warn "YAML parsing failed for #{args.name}: #{error.message}"
        
        callback null,
          content: [{
            type: 'text'
            text: "Context: #{args.name}\n\n#{contextContent}"
          }]
          isError: false
      .catch (error) ->
        callback
          code: -32603
          message: "Failed to read context '#{args.name}': #{error.message}"
    .catch (error) ->
      callback
        code: -32603
        message: "Failed to find context '#{args.name}': #{error.message}"
  catch error
    callback
      code: -32603
      message: "Failed to retrieve context '#{args.name}': #{error.message}"

handleSetContext = (args, callback) ->
  try
    unless args.name and args.content
      return callback
        code: -32602
        message: 'Missing required parameters: name, content'
    
    # Validate context name (alphanumeric, hyphens, underscores only)
    unless /^[a-zA-Z0-9_-]+$/.test(args.name)
      return callback
        code: -32602
        message: 'Invalid context name. Use only letters, numbers, hyphens, and underscores.'
    
    # Build context data structure
    contextData = {}
    
    # Add inheritance if specified
    if args.inherits? and args.inherits.length > 0
      contextData.inherits = args.inherits
    
    # Add metadata
    contextData.updated = new Date().toISOString()
    contextData.version = '1.0'
    
    # Parse existing content if it's YAML, otherwise treat as plain text
    try
      existingData = yaml.load(args.content)
      if typeof existingData is 'object' and existingData isnt null
        Object.assign(contextData, existingData)
      else
        contextData.content = args.content
    catch
      contextData.content = args.content
    
    # Ensure contexts directory exists
    contextsDir = path.join(process.cwd(), 'state', 'contexts')
    fs.mkdir(contextsDir, { recursive: true }).then ->
      # Write context file
      contextPath = path.join(contextsDir, "#{args.name}.yaml")
      contextYaml = yaml.dump(contextData)
      fs.writeFile(contextPath, contextYaml, 'utf8').then ->
        callback null,
          content: [{
            type: 'text'
            text: "Successfully updated context: #{args.name}"
          }]
          isError: false
      .catch (error) ->
        callback
          code: -32603
          message: "Failed to write context '#{args.name}': #{error.message}"
    .catch (error) ->
      callback
        code: -32603
        message: "Failed to create contexts directory: #{error.message}"
  catch error
    callback
      code: -32603
      message: "Failed to set context '#{args.name}': #{error.message}"

handleListContexts = (args, callback) ->
  try
    contextsDir = path.join(process.cwd(), 'state', 'contexts')
    
    # Check if contexts directory exists
    fs.access(contextsDir).then ->
      # Read all subdirectories and files
      readContextsRecursively = (dir, category = '') ->
        fs.readdir(dir, { withFileTypes: true }).then (entries) ->
          contexts = []
          
          for entry in entries
            if entry.isDirectory()
              # Recursively read subdirectories
              subContexts = await readContextsRecursively(path.join(dir, entry.name), entry.name)
              contexts = contexts.concat(subContexts)
            else if entry.name.endsWith('.yaml')
              contextName = entry.name.replace('.yaml', '')
              contextPath = path.join(dir, entry.name)
              
              try
                contextContent = await fs.readFile(contextPath, 'utf8')
                contextData = yaml.load(contextContent)
                
                # Extract metadata
                stats = await fs.stat(contextPath)
                context = {
                  name: contextName
                  modified: stats.mtime.toISOString()
                  size: stats.size
                  category: category or contextData?.category or 'uncategorized'
                }
                
                # Add description if available
                if contextData?.description?
                  context.description = contextData.description
                
                # Add inheritance info if available
                if contextData?.inherits?
                  context.inherits = contextData.inherits
                
                # Filter by category if specified
                if args.category? and context.category isnt args.category
                  continue
                
                # Filter by pattern if specified
                if args.pattern?
                  pattern = args.pattern.replace(/\*/g, '.*')
                  regex = new RegExp(pattern, 'i')
                  unless regex.test(contextName)
                    continue
                
                contexts.push(context)
              catch error
                # Skip malformed context files
                continue
          
          return contexts
      
      readContextsRecursively(contextsDir).then (contextList) ->
        # Sort by name
        contextList.sort((a, b) -> a.name.localeCompare(b.name))
        
        # Format output
        if contextList.length is 0
          resultText = 'No contexts found matching criteria'
        else
          resultText = 'Available Contexts:\n\n'
          for context in contextList
            line = "- #{context.name}"
            if context.category and context.category isnt 'uncategorized'
              line += " (#{context.category})"
            if context.description?
              line += " - #{context.description}"
            if context.inherits?
              line += " [inherits: #{context.inherits.join(', ')}]"
            resultText += line + '\n'
        
        callback null,
          content: [{
            type: 'text'
            text: resultText
          }]
          isError: false
      .catch (error) ->
        callback
          code: -32603
          message: "Failed to read contexts: #{error.message}"
    .catch ->
      callback null,
        content: [{
          type: 'text'
          text: 'No contexts directory found. Contexts: none available'
        }]
        isError: false
  catch error
    callback
      code: -32603
      message: "Failed to list contexts: #{error.message}"

handleInheritContext = (args, callback) ->
  try
    unless args.name and args.parents
      return callback
        code: -32602
        message: 'Missing required parameters: name, parents'
    
    # Validate context name
    unless /^[a-zA-Z0-9_-]+$/.test(args.name)
      return callback
        code: -32602
        message: 'Invalid context name. Use only letters, numbers, hyphens, and underscores.'
    
    # Validate that parent contexts exist
    contextsDir = path.join(process.cwd(), 'state', 'contexts')
    
    validateParents = (parents) ->
      for parent in parents
        parentPaths = [
          path.join(contextsDir, 'core', "#{parent}.yaml")
          path.join(contextsDir, 'domains', "#{parent}.yaml")
          path.join(contextsDir, 'projects', "#{parent}.yaml")
          path.join(contextsDir, "#{parent}.yaml")
        ]
        
        found = false
        for parentPath in parentPaths
          try
            await fs.access(parentPath)
            found = true
            break
          catch
            continue
        
        unless found
          throw new Error("Parent context '#{parent}' not found")
    
    validateParents(args.parents).then ->
      # Build new context data
      contextData = {
        inherits: args.parents
        created: new Date().toISOString()
        version: '1.0'
      }
      
      if args.description?
        contextData.description = args.description
      
      if args.content?
        contextData.content = args.content
      
      # Ensure contexts directory exists
      fs.mkdir(contextsDir, { recursive: true }).then ->
        # Write new context file
        contextPath = path.join(contextsDir, "#{args.name}.yaml")
        contextYaml = yaml.dump(contextData)
        fs.writeFile(contextPath, contextYaml, 'utf8').then ->
          callback null,
            content: [{
              type: 'text'
              text: "Created inherited context: #{args.name}\nInherits from: #{args.parents.join(', ')}"
            }]
            isError: false
        .catch (error) ->
          callback
            code: -32603
            message: "Failed to write inherited context '#{args.name}': #{error.message}"
      .catch (error) ->
        callback
          code: -32603
          message: "Failed to create contexts directory: #{error.message}"
    .catch (error) ->
      callback
        code: -32603
        message: error.message
  catch error
    callback
      code: -32603
      message: "Failed to create inherited context '#{args.name}': #{error.message}"

handleSearchContexts = (args, callback) ->
  try
    unless args.query
      return callback
        code: -32602
        message: 'Missing required parameter: query'
    
    contextsDir = path.join(process.cwd(), 'state', 'contexts')
    
    # Check if contexts directory exists
    fs.access(contextsDir).then ->
      # Read all context files recursively
      searchContextsRecursively = (dir) ->
        fs.readdir(dir, { withFileTypes: true }).then (entries) ->
          results = []
          searchTerm = args.query.toLowerCase()
          
          for entry in entries
            if entry.isDirectory()
              # Recursively search subdirectories
              subResults = await searchContextsRecursively(path.join(dir, entry.name))
              results = results.concat(subResults)
            else if entry.name.endsWith('.yaml')
              contextName = entry.name.replace('.yaml', '')
              contextPath = path.join(dir, entry.name)
              
              try
                contextContent = await fs.readFile(contextPath, 'utf8')
                contextData = yaml.load(contextContent)
                
                score = 0
                matches = []
                
                # Search in context name (high weight)
                if contextName.toLowerCase().includes(searchTerm)
                  score += 100
                  matches.push('name')
                
                # Search in description (medium weight)
                if contextData?.description?
                  if contextData.description.toLowerCase().includes(searchTerm)
                    score += 50
                    matches.push('description')
                
                # Search in content (lower weight but more detailed)
                contentText = if typeof contextData?.content is 'string'
                  contextData.content
                else
                  contextContent
                
                if contentText.toLowerCase().includes(searchTerm)
                  score += 25
                  matches.push('content')
                
                # Only include results with matches
                if score > 0
                  result = {
                    name: contextName
                    score: score
                    matches: matches
                  }
                  
                  # Add excerpt if requested
                  if args.includeContent ? true
                    # Find the first occurrence and extract context
                    lowerContent = contentText.toLowerCase()
                    index = lowerContent.indexOf(searchTerm)
                    if index >= 0
                      start = Math.max(0, index - 50)
                      end = Math.min(contentText.length, index + searchTerm.length + 50)
                      excerpt = contentText.substring(start, end)
                      if start > 0
                        excerpt = '...' + excerpt
                      if end < contentText.length
                        excerpt = excerpt + '...'
                      result.excerpt = excerpt
                  
                  results.push(result)
              catch error
                # Skip malformed files
                continue
          
          return results
      
      searchContextsRecursively(contextsDir).then (results) ->
        # Sort by score descending
        results.sort((a, b) -> b.score - a.score)
        
        # Apply limit
        limit = Math.min(args.limit ? 10, results.length)
        results = results.slice(0, limit)
        
        # Format output
        if results.length is 0
          resultText = "No contexts found matching '#{args.query}'"
        else
          resultText = "Search Results for '#{args.query}':\n\n"
          for result in results
            resultText += "## #{result.name}\n"
            resultText += "Score: #{result.score} (matched: #{result.matches.join(', ')})\n"
            if result.excerpt?
              resultText += "#{result.excerpt}\n"
            resultText += '\n'
        
        callback null,
          content: [{
            type: 'text'
            text: resultText
          }]
          isError: false
      .catch (error) ->
        callback
          code: -32603
          message: "Failed to search contexts: #{error.message}"
    .catch ->
      callback null,
        content: [{
          type: 'text'
          text: 'No contexts directory found for searching'
        }]
        isError: false
  catch error
    callback
      code: -32603
      message: "Failed to search contexts: #{error.message}"

module.exports = {
  listTools
  callTool
}
