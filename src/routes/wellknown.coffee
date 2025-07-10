# FILENAME: { ClodForest/src/routes/wellknown.coffee }
# Well-known endpoints for MCP discovery
# Note: OAuth2 discovery is handled by oidc-provider at /.well-known/oauth-authorization-server

express = require 'express'
router  = express.Router()

# OAuth2 Authorization Server Metadata is now handled by oidc-provider
# The endpoint /.well-known/oauth-authorization-server is automatically provided

# OAuth2 Protected Resource Metadata (RFC 8707)
router.get '/oauth-protected-resource', (req, res) ->
  baseUrl = "#{req.protocol}://#{req.get('host')}"

  res.json
    resource:                baseUrl + "/api/mcp"  # The actual MCP API endpoint
    authorization_servers:   [baseUrl + "/oauth"]  # Our OAuth issuer
    scopes_supported:        ['openid', 'mcp', 'read', 'write']  # Match OAuth server scopes
    bearer_methods_supported: ['header']

# MCP Server Discovery Metadata
router.get '/mcp-server', (req, res) ->
  baseUrl = "#{req.protocol}://#{req.get('host')}"

  res.json
    name:             'ClodForest MCP Server'
    version:          '1.0.0'
    protocol_version: '2025-06-18'
    description:      'ClodForest Model Context Protocol Server for LLM collaboration'
    endpoint:         "#{baseUrl}/api/mcp"
    transport:        'http'
    authentication:
      type:                'oauth2'
      authorization_server: "#{baseUrl}/.well-known/oauth-authorization-server"
      scopes_required:     ['mcp']
    capabilities:
      tools:    true
      resources: false
      prompts:  false
      logging:  false
    tools: [
      name: 'read_state_file'
      description: 'Read files from the state directory'
      inputSchema:
        type: 'object'
        properties:
          path:
            type: 'string'
            description: 'Path to the file within the state directory'
        required: ['path']
    ,
      name: 'write_state_file'
      description: 'Write files to the state directory'
      inputSchema:
        type: 'object'
        properties:
          path:
            type: 'string'
            description: 'Path to the file within the state directory'
          content:
            type: 'string'
            description: 'Content to write to the file'
        required: ['path', 'content']
    ,
      name: 'list_state_files'
      description: 'List files and directories in the state directory'
      inputSchema:
        type: 'object'
        properties:
          path:
            type: 'string'
            description: 'Path within the state directory to list (defaults to root)'
            default: '.'
    ]
    contact:
      name:  'ClodForest Support'
      email: 'support@clodforest.org'
      url:   "#{baseUrl}/support"
    documentation: "#{baseUrl}/docs/mcp"

module.exports = router
