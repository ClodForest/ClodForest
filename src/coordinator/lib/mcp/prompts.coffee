# FILENAME: { ClodForest/src/coordinator/lib/mcp/prompts.coffee }
# MCP Prompts Implementation
# Provide workflow templates for ClodForest interactions

config = require '../config'

# Prompt definitions
PROMPTS = [
  {
    name: 'load_context'
    description: 'Load a specific context file from ClodForest'
    arguments: [
      {
        name: 'context_path'
        description: 'Path to the context file (e.g., core/robert_identity.yaml)'
        required: true
      }
    ]
  }
  
  {
    name: 'session_handoff'
    description: 'Create a session handoff capsule for continuing work'
    arguments: [
      {
        name: 'session_id'
        description: 'Identifier for the current session'
        required: true
      }
      {
        name: 'summary'
        description: 'Summary of work completed and next steps'
        required: true
      }
    ]
  }
  
  {
    name: 'explore_repository'
    description: 'Explore the structure of a ClodForest repository'
    arguments: [
      {
        name: 'repository'
        description: 'Name of the repository to explore'
        required: true
      }
    ]
  }
]

# List available prompts
listPrompts = (callback) ->
  callback null, PROMPTS

# Get a specific prompt with filled template
getPrompt = (promptName, args, callback) ->
  switch promptName
    when 'load_context'
      unless args.context_path
        return callback
          code: -32602
          message: 'Missing required argument: context_path'
      
      messages = [
        {
          role: 'user'
          content:
            type: 'text'
            text: """
            Please load the following context from ClodForest:
            
            Context Path: #{args.context_path}
            
            Use the clodforest.readFile tool to retrieve the context file from the 'contexts' repository.
            """
        }
      ]
      
      callback null, { messages }
    
    when 'session_handoff'
      unless args.session_id and args.summary
        return callback
          code: -32602
          message: 'Missing required arguments: session_id, summary'
      
      messages = [
        {
          role: 'user'
          content:
            type: 'text'
            text: """
            # Session Handoff Capsule
            
            Session ID: #{args.session_id}
            Timestamp: #{new Date().toISOString()}
            
            ## Work Summary
            #{args.summary}
            
            ## Context Files to Load
            Please use the ClodForest MCP tools to:
            1. List available context files using clodforest.browseRepository
            2. Load relevant contexts for continuation
            3. Check the current system status with clodforest.checkHealth
            
            ## Next Steps
            Based on the loaded contexts and current state, continue the work as outlined in the summary.
            """
        }
      ]
      
      callback null, { messages }
    
    when 'explore_repository'
      unless args.repository
        return callback
          code: -32602
          message: 'Missing required argument: repository'
      
      messages = [
        {
          role: 'user'
          content:
            type: 'text'
            text: """
            Let's explore the ClodForest repository: #{args.repository}
            
            Please use the following tools in sequence:
            1. clodforest.browseRepository - to see the structure
            2. clodforest.readFile - to examine specific files of interest
            3. clodforest.gitStatus - to check the repository status (if available)
            
            Start by browsing the root of the repository to understand its organization.
            """
        }
      ]
      
      callback null, { messages }
    
    else
      callback
        code: -32602
        message: "Unknown prompt: #{promptName}"

module.exports = {
  listPrompts
  getPrompt
}
