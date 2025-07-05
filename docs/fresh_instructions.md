# ClodForest Implementation Instructions

## Mission: Build Production OAuth2 + MCP Server for LLM Collaboration

Create a complete server that lets multiple LLM instances collaborate through shared state management.

## Core Requirements

### OAuth2 Server
- Use `oauth2-server` library
- Client credentials grant flow  
- RFC 6749/6750/8414 compliant
- Proper well-known endpoints
- Bearer token authentication

### MCP Server  
- Use `@modelcontextprotocol/sdk`
- MCP 2025-06-18 protocol compliance
- JSON-RPC 2.0 transport
- OAuth2-protected endpoints

### Initial Tools to Implement

**State Directory Access Only:**
- `read_state_file` - Read files from state/ directory
- `write_state_file` - Write files to state/ directory  
- `list_state_files` - Browse state/ directory structure

*Note: Stop after implementing state file tools. Other features (messaging, context consolidation, project write access) will be added later once the basic workflow is established.*

## Target Endpoints

```
/.well-known/oauth-authorization-server    # RFC 8414
/.well-known/oauth-protected-resource      # RFC 8707  
/oauth/register                           # Client registration
/oauth/token                              # Token endpoint
/api/mcp                                  # MCP protocol endpoint
/api/health                               # Health check
```

## Architecture Overview

```
Express App
├── OAuth2 Server (/oauth/*)
├── Well-known endpoints (/.well-known/*)  
├── MCP Server (/api/mcp) [OAuth2 protected]
│   └── State Management Tools
└── Health/Admin (/api/health)
```

## Implementation Strategy

### 1. Foundation Setup
- Use existing package.json dependencies
- Set up Express application structure
- Configure for production deployment

### 2. OAuth2 Implementation
- Configure oauth2-server with file system persistence
- Implement client_credentials grant type
- Generate RFC-compliant well-known metadata
- Support scopes: `['mcp', 'read', 'write']`

### 3. MCP Integration  
- Initialize @modelcontextprotocol/sdk server
- Connect OAuth2 authentication middleware
- Register state management tools
- Ensure JSON-RPC 2.0 compliance

### 4. State Tools Implementation
- Implement secure file system access to state/ directory
- Validate file paths to prevent directory traversal
- Support common file operations (read, write, list)
- Handle proper error responses

## Project Structure

```
src/
├── app.js              # Main Express app
├── oauth/              # OAuth2 server configuration  
│   ├── server.js       # OAuth2 server setup
│   └── model.js        # OAuth2 data model (file-based)
├── mcp/                # MCP server and tools
│   ├── server.js       # MCP server setup
│   └── tools/          # Tool implementations
│       └── state.js    # State directory access tools
├── middleware/         # Authentication and security
│   ├── auth.js         # OAuth2 middleware
│   └── security.js     # CORS, helmet, etc.
└── routes/             # Express route handlers
    ├── wellknown.js    # Well-known endpoints
    └── health.js       # Health check

state/                  # LLM shared state directory
└── (files managed by LLMs)
```

## Success Criteria

### OAuth2 Flow Works
```bash
# Register client
curl -X POST https://clodforest.thatsnice.org/oauth/register \
  -H 'Content-Type: application/json' \
  -d '{"client_name": "test-client", "grant_types": ["client_credentials"]}'

# Get token  
curl -X POST https://clodforest.thatsnice.org/oauth/token \
  -H 'Authorization: Basic <client_creds>' \
  -d 'grant_type=client_credentials&scope=mcp'
```

### MCP Flow Works
```javascript
// Initialize MCP connection
{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}

// List available tools
{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}

// Read state file
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"read_state_file","arguments":{"path":"example.md"}},"id":3}

// Write state file  
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"write_state_file","arguments":{"path":"example.md","content":"Hello world"}},"id":4}

// List state files
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"list_state_files","arguments":{"path":"."}},"id":5}
```

## Security Requirements

- **HTTPS only** for production
- **Bearer token validation** for all MCP endpoints
- **Path validation** to prevent directory traversal attacks
- **Scope checking** for appropriate permissions
- **CORS configuration** for web clients
- **Error handling** that doesn't leak sensitive information

## Environment Configuration

- **Production deployment** to clodforest.thatsnice.org
- **File system persistence** for OAuth2 data and state
- **Environment variables** for sensitive configuration
- **Process management** for production stability

## Implementation Notes

1. **Follow library best practices** - Use oauth2-server and @modelcontextprotocol/sdk documentation as the authoritative guide
2. **RFC compliance first** - Ensure proper OAuth2 and MCP protocol adherence  
3. **Security by default** - Implement proper authentication and authorization
4. **Production ready** - Deploy directly to production, no staging environment
5. **Iterative development** - Get basic functionality working, then expand

## Testing Strategy

- **Manual testing** with curl commands
- **Real Claude.ai integration** as primary test
- **Production deployment** for validation
- **Monitor logs** for issues and improvements

## Next Steps After State Tools

Once state file read/write tools are working and Claude.ai can successfully connect and use them:

1. LLM message passing system
2. Context consolidation workflow
3. Project write access with approval tokens
4. Enhanced collaboration features

*These will be implemented in subsequent phases once the basic workflow is established and proven.*