# ClodForest Context MCP Tools Implementation

**Purpose**: Add the missing context operations to complete the MCP transformation  
**Target**: Extend `src/coordinator/lib/mcp/tools.coffee` with 5 new context tools  
**Integration**: Works with existing CoffeeScript MCP implementation

---

## Context Tools to Add

### 1. `clodforest.getContext`
**Description**: Retrieve context data by name with inheritance resolution  
**Core Value**: Access ClodForest's context inheritance system via MCP

### 2. `clodforest.setContext`
**Description**: Create or update context data  
**Core Value**: Programmatic context management from MCP clients

### 3. `clodforest.listContexts`
**Description**: List all available contexts with metadata  
**Core Value**: Context discovery and navigation

### 4. `clodforest.inheritContext`
**Description**: Create new context that inherits from existing contexts  
**Core Value**: Dynamic context inheritance - ClodForest's unique feature

### 5. `clodforest.searchContexts`
**Description**: Search context content and metadata  
**Core Value**: Context intelligence and retrieval

---

## Implementation Code

Add this to `src/coordinator/lib/mcp/tools.coffee`:

```coffeescript
# Context operation tools - ClodForest's core value proposition
contextTools =
  'clodforest.getContext':
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
    handler: (args) ->
      try
        # Assuming ClodForest has a context system available
        # This may need adjustment based on actual implementation
        contextPath = path.join(process.cwd(), 'state', 'contexts', "#{args.name}.yaml")
        
        if not await fs.access(contextPath).then(-> true).catch(-> false)
          throw new Error("Context '#{args.name}' not found")
        
        contextContent = await fs.readFile(contextPath, 'utf8')
        
        # If inheritance resolution is enabled, process parent contexts
        if args.resolveInheritance ? true
          contextData = yaml.parse(contextContent)
          
          if contextData.inherits?
            inheritedContent = []
            for parent in contextData.inherits
              parentPath = path.join(process.cwd(), 'state', 'contexts', "#{parent}.yaml")
              if await fs.access(parentPath).then(-> true).catch(-> false)
                parentContent = await fs.readFile(parentPath, 'utf8')
                inheritedContent.push("# Inherited from #{parent}\n#{parentContent}")
            
            if inheritedContent.length > 0
              contextContent = inheritedContent.join('\n\n---\n\n') + '\n\n---\n\n' + contextContent
        
        return {
          content: [{
            type: 'text'
            text: "Context: #{args.name}\n\n#{contextContent}"
          }]
        }
      catch error
        throw new Error("Failed to retrieve context '#{args.name}': #{error.message}")

  'clodforest.setContext':
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
    handler: (args) ->
      try
        # Validate context name (alphanumeric, hyphens, underscores only)
        if not /^[a-zA-Z0-9_-]+$/.test(args.name)
          throw new Error("Invalid context name. Use only letters, numbers, hyphens, and underscores.")
        
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
          existingData = yaml.parse(args.content)
          if typeof existingData is 'object'
            Object.assign(contextData, existingData)
          else
            contextData.content = args.content
        catch
          contextData.content = args.content
        
        # Ensure contexts directory exists
        contextsDir = path.join(process.cwd(), 'state', 'contexts')
        await fs.mkdir(contextsDir, { recursive: true })
        
        # Write context file
        contextPath = path.join(contextsDir, "#{args.name}.yaml")
        contextYaml = yaml.stringify(contextData)
        await fs.writeFile(contextPath, contextYaml, 'utf8')
        
        return {
          content: [{
            type: 'text'
            text: "Successfully updated context: #{args.name}"
          }]
        }
      catch error
        throw new Error("Failed to set context '#{args.name}': #{error.message}")

  'clodforest.listContexts':
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
      required: []
    handler: (args) ->
      try
        contextsDir = path.join(process.cwd(), 'state', 'contexts')
        
        # Check if contexts directory exists
        if not await fs.access(contextsDir).then(-> true).catch(-> false)
          return {
            content: [{
              type: 'text'
              text: 'No contexts directory found. Contexts: none available'
            }]
          }
        
        # Read all YAML files in contexts directory
        files = await fs.readdir(contextsDir)
        yamlFiles = files.filter((file) -> file.endsWith('.yaml'))
        
        contextList = []
        
        for file in yamlFiles
          contextName = file.replace('.yaml', '')
          contextPath = path.join(contextsDir, file)
          
          try
            contextContent = await fs.readFile(contextPath, 'utf8')
            contextData = yaml.parse(contextContent)
            
            # Extract metadata
            stats = await fs.stat(contextPath)
            context = {
              name: contextName
              modified: stats.mtime.toISOString()
              size: stats.size
            }
            
            # Add description if available
            if contextData?.description?
              context.description = contextData.description
            
            # Add category if available
            if contextData?.category?
              context.category = contextData.category
            
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
              if not regex.test(contextName)
                continue
            
            contextList.push(context)
          catch error
            # Skip malformed context files
            continue
        
        # Sort by name
        contextList.sort((a, b) -> a.name.localeCompare(b.name))
        
        # Format output
        if contextList.length is 0
          resultText = 'No contexts found matching criteria'
        else
          resultText = 'Available Contexts:\n\n'
          for context in contextList
            line = "- #{context.name}"
            if context.category?
              line += " (#{context.category})"
            if context.description?
              line += " - #{context.description}"
            if context.inherits?
              line += " [inherits: #{context.inherits.join(', ')}]"
            resultText += line + '\n'
        
        return {
          content: [{
            type: 'text'
            text: resultText
          }]
        }
      catch error
        throw new Error("Failed to list contexts: #{error.message}")

  'clodforest.inheritContext':
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
    handler: (args) ->
      try
        # Validate context name
        if not /^[a-zA-Z0-9_-]+$/.test(args.name)
          throw new Error("Invalid context name. Use only letters, numbers, hyphens, and underscores.")
        
        # Validate that parent contexts exist
        contextsDir = path.join(process.cwd(), 'state', 'contexts')
        for parent in args.parents
          parentPath = path.join(contextsDir, "#{parent}.yaml")
          if not await fs.access(parentPath).then(-> true).catch(-> false)
            throw new Error("Parent context '#{parent}' not found")
        
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
        await fs.mkdir(contextsDir, { recursive: true })
        
        # Write new context file
        contextPath = path.join(contextsDir, "#{args.name}.yaml")
        contextYaml = yaml.stringify(contextData)
        await fs.writeFile(contextPath, contextYaml, 'utf8')
        
        return {
          content: [{
            type: 'text'
            text: "Created inherited context: #{args.name}\nInherits from: #{args.parents.join(', ')}"
          }]
        }
      catch error
        throw new Error("Failed to create inherited context '#{args.name}': #{error.message}")

  'clodforest.searchContexts':
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
    handler: (args) ->
      try
        contextsDir = path.join(process.cwd(), 'state', 'contexts')
        
        # Check if contexts directory exists
        if not await fs.access(contextsDir).then(-> true).catch(-> false)
          return {
            content: [{
              type: 'text'
              text: 'No contexts directory found for searching'
            }]
          }
        
        # Read all context files
        files = await fs.readdir(contextsDir)
        yamlFiles = files.filter((file) -> file.endsWith('.yaml'))
        
        results = []
        searchTerm = args.query.toLowerCase()
        
        for file in yamlFiles
          contextName = file.replace('.yaml', '')
          contextPath = path.join(contextsDir, file)
          
          try
            contextContent = await fs.readFile(contextPath, 'utf8')
            contextData = yaml.parse(contextContent)
            
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
            contentText = if typeof contextData.content is 'string'
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
        
        return {
          content: [{
            type: 'text'
            text: resultText
          }]
        }
      catch error
        throw new Error("Failed to search contexts: #{error.message}")

# Export the context tools to be merged with existing tools
module.exports = { contextTools }
```

---

## Integration Instructions

### Step 1: Add Dependencies
Add to the top of `src/coordinator/lib/mcp/tools.coffee`:

```coffeescript
fs   = require 'node:fs/promises'
path = require 'node:path'
yaml = require 'yaml'  # May need: npm install yaml
```

### Step 2: Merge with Existing Tools
In the main tools export section, merge the context tools:

```coffeescript
# Existing tools (repository operations)
tools = {
  'clodforest.getTime': { ... }
  'clodforest.checkHealth': { ... }
  'clodforest.listRepositories': { ... }
  'clodforest.browseRepository': { ... }
  'clodforest.readFile': { ... }
  'clodforest.gitStatus': { ... }
}

# Import and merge context tools
{ contextTools } = require './context-tools'  # If in separate file
Object.assign(tools, contextTools)

module.exports = { tools }
```

### Step 3: Test Context Operations
```bash
# List available contexts
curl -X POST http://localhost:3000/api/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "clodforest.listContexts"
    }
  }'

# Get a specific context
curl -X POST http://localhost:3000/api/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "clodforest.getContext",
      "arguments": {
        "name": "robert-identity",
        "resolveInheritance": true
      }
    }
  }'

# Search contexts
curl -X POST http://localhost:3000/api/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "clodforest.searchContexts",
      "arguments": {
        "query": "collaboration",
        "limit": 5
      }
    }
  }'
```

---

## Expected Context Directory Structure

The implementation assumes contexts are stored as YAML files in:
```
state/contexts/
├── robert-identity.yaml
├── collaboration-patterns.yaml
├── general-development.yaml
├── teaching-moments.yaml
└── [other-context-files].yaml
```

Each context file should follow this structure:
```yaml
description: "Brief description of this context"
category: "core|domains|projects"
inherits:
  - parent-context-1
  - parent-context-2
version: "1.0"
updated: "2025-07-04T18:30:00Z"
content: |
  The actual context content goes here.
  This can be multi-line text, instructions,
  or any other relevant information.
```

---

## Claude Desktop Integration

Once implemented, Claude Desktop will be able to:

1. **Browse Contexts**: `clodforest.listContexts()` - Discover available contexts
2. **Access Context Data**: `clodforest.getContext("robert-identity")` - Get full context with inheritance
3. **Create New Contexts**: `clodforest.setContext()` - Store session insights
4. **Inherit Context**: `clodforest.inheritContext()` - Build specialized contexts
5. **Search Intelligence**: `clodforest.searchContexts("collaboration")` - Find relevant contexts

This transforms ClodForest into a **premium MCP context server** - the only one that offers sophisticated context inheritance and session handoff capabilities!

---

## Success Criteria

✅ **Context Discovery**: Can list and browse all available contexts  
✅ **Context Access**: Can retrieve contexts with full inheritance resolution  
✅ **Context Management**: Can create and update contexts programmatically  
✅ **Context Intelligence**: Can search and find relevant contexts  
✅ **Inheritance System**: Can create derived contexts that inherit from parents  
✅ **Claude Desktop Ready**: All tools work seamlessly with Claude Desktop MCP client

This completes the transformation from custom REST API to **industry-standard MCP server with ClodForest's unique context intelligence**! 🚀