# FILENAME: { ClodForest/src/routes/wellknown.coffee }
# Well-known endpoints for OAuth2 and MCP discovery

express = require 'express'
router  = express.Router()

# OAuth2 Authorization Server Metadata (RFC 8414)
router.get '/oauth-authorization-server', (req, res) ->
  baseUrl = "#{req.protocol}://#{req.get('host')}"
  
  res.json
    issuer:                                    baseUrl
    authorization_endpoint:                    "#{baseUrl}/oauth/authorize"
    token_endpoint:                            "#{baseUrl}/oauth/token"
    token_endpoint_auth_methods_supported:     ['client_secret_basic', 'client_secret_post']
    token_endpoint_auth_signing_alg_values_supported: ['RS256', 'HS256']
    userinfo_endpoint:                         "#{baseUrl}/oauth/userinfo"
    registration_endpoint:                     "#{baseUrl}/oauth/register"
    introspection_endpoint:                    "#{baseUrl}/oauth/introspect"
    revocation_endpoint:                       "#{baseUrl}/oauth/revoke"
    scopes_supported:                          ['mcp', 'read', 'write']
    response_types_supported:                  ['token']
    grant_types_supported:                     ['client_credentials']
    subject_types_supported:                   ['public']
    id_token_signing_alg_values_supported:     ['RS256']
    claims_supported:                          ['sub', 'iss', 'aud', 'exp', 'iat']
    code_challenge_methods_supported:          ['S256']
    service_documentation:                     "#{baseUrl}/docs"
    ui_locales_supported:                      ['en-US']
    op_policy_uri:                             "#{baseUrl}/policy"
    op_tos_uri:                                "#{baseUrl}/terms"

# OAuth2 Protected Resource Metadata (RFC 8707)
router.get '/oauth-protected-resource', (req, res) ->
  baseUrl = "#{req.protocol}://#{req.get('host')}"
  
  res.json
    resource:                baseUrl
    authorization_servers:   [baseUrl]
    scopes_supported:        ['mcp', 'read', 'write']
    bearer_methods_supported: ['header']
    resource_documentation:  "#{baseUrl}/docs/mcp"
    scope_policy_uri:        "#{baseUrl}/policy/scopes"

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
