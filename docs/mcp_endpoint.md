# FILENAME: { ClodForest/docs/mcp_endpoint.md }
# ClodForest MCP (Model Context Protocol) Endpoint

## Overview

ClodForest provides a fully-compliant MCP server endpoint at `/api/mcp` that implements the Model Context Protocol specification version 2025-06-18. This allows AI assistants and other MCP clients to interact with ClodForest's data and operations through a standardized interface.

## Endpoint

```
POST /api/mcp
Content-Type: application/json
```

## Protocol

The endpoint uses JSON-RPC 2.0 for all communications. Each request must include:
- `jsonrpc`: "2.0"
- `method`: The MCP method to call
- `params`: Method parameters (optional)
- `id`: Request ID (omit for notifications)

## Available Methods

### Core Methods

#### initialize
Initialize the MCP session.

```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "clientInfo": {
      "name": "your-client",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

Returns server capabilities and protocol version.

### Resource Methods

#### resources/list
List all available resources.

```json
{
  "jsonrpc": "2.0",
  "method": "resources/list",
  "params": {},
  "id": 2
}
```

#### resources/get
Get a specific resource by URI.

```json
{
  "jsonrpc": "2.0",
  "method": "resources/get",
  "params": {
    "uri": "clodforest://info"
  },
  "id": 3
}
```

Available resource URIs:
- `clodforest://info` - Service information
- `clodforest://health` - Health status
- `clodforest://contexts/{path}` - Context files (e.g., `clodforest://contexts/core/robert_identity.yaml`)

### Tool Methods

#### tools/list
List all available tools.

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "params": {},
  "id": 4
}
```

#### tools/call
Execute a tool.

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "clodforest.getTime",
    "arguments": {
      "format": "iso8601"
    }
  },
  "id": 5
}
```

Available tools:
- `clodforest.getTime` - Get current time (formats: iso8601, unix, rfc2822, milliseconds)
- `clodforest.checkHealth` - Check service health
- `clodforest.listRepositories` - List available repositories
- `clodforest.browseRepository` - Browse repository contents
- `clodforest.readFile` - Read a file from a repository
- `clodforest.gitStatus` - Get git status (if git operations enabled)

### Prompt Methods

#### prompts/list
List available workflow prompts.

```json
{
  "jsonrpc": "2.0",
  "method": "prompts/list",
  "params": {},
  "id": 6
}
```

#### prompts/get
Get a specific prompt template.

```json
{
  "jsonrpc": "2.0",
  "method": "prompts/get",
  "params": {
    "name": "load_context",
    "arguments": {
      "context_path": "core/robert_identity.yaml"
    }
  },
  "id": 7
}
```

Available prompts:
- `load_context` - Load a specific context file
- `session_handoff` - Create a session handoff capsule
- `explore_repository` - Explore repository structure

## Example Usage

### 1. Initialize Session

```bash
curl -X POST http://localhost:8080/api/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "clientInfo": {
        "name": "example-client",
        "version": "1.0.0"
      }
    },
    "id": 1
  }'
```

### 2. List Available Tools

```bash
curl -X POST http://localhost:8080/api/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "params": {},
    "id": 2
  }'
```

### 3. Get Current Time

```bash
curl -X POST http://localhost:8080/api/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "clodforest.getTime",
      "arguments": {
        "format": "iso8601"
      }
    },
    "id": 3
  }'
```

### 4. Read a Context File

```bash
curl -X POST http://localhost:8080/api/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "resources/get",
    "params": {
      "uri": "clodforest://contexts/core/robert_identity.yaml"
    },
    "id": 4
  }'
```

## Error Handling

The endpoint returns standard JSON-RPC 2.0 error responses:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": "Additional error details"
  },
  "id": 1
}
```

Error codes:
- `-32700`: Parse error
- `-32600`: Invalid request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error
- `-32002`: Not initialized (MCP-specific)

## Server Capabilities

The server advertises the following capabilities:
- **resources**: Read-only access to ClodForest data
- **tools**: Execute ClodForest operations
- **prompts**: Workflow templates for common tasks

The server does not currently support:
- Resource change notifications
- Tool change notifications
- Prompt change notifications
- Sampling
- Roots
- Elicitation

## Testing the Endpoint

A comprehensive test suite is available:

```bash
npm test -- t/mcp.test.coffee
```

The test suite covers:
- JSON-RPC protocol compliance
- All MCP methods
- Error handling
- Integration flows

## Integration with MCP Clients

To use ClodForest with an MCP client:

1. Configure the client to connect to: `http://your-server:8080/api/mcp`
2. The client should initialize the session first
3. Then it can list and use resources, tools, and prompts

## OAuth2 Authentication

ClodForest now supports OAuth2 authentication for the MCP endpoint. When enabled, all MCP requests must include a valid Bearer token.

### Enabling OAuth2

Set the environment variable:
```bash
ENABLE_OAUTH2=true npm start
```

### OAuth2 Flow

1. **Register a client application** (development mode only):
```bash
curl -X POST http://localhost:8080/oauth/clients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My MCP Client",
    "redirect_uris": ["http://localhost:3000/callback"],
    "scope": "mcp read write"
  }'
```

2. **Authorize the user**:
Direct users to: `/oauth/authorize?client_id={client_id}&redirect_uri={redirect_uri}&response_type=code&scope=mcp`

3. **Exchange authorization code for tokens**:
```bash
curl -X POST http://localhost:8080/oauth/token \
  -H "Authorization: Basic {base64(client_id:client_secret)}" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "authorization_code",
    "code": "{authorization_code}",
    "redirect_uri": "{redirect_uri}"
  }'
```

4. **Use the access token** in MCP requests:
```bash
curl -X POST http://localhost:8080/api/mcp \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {},
    "id": 1
  }'
```

### Token Management

- Access tokens expire after 1 hour
- Refresh tokens expire after 30 days
- Use the refresh token to get new access tokens:

```bash
curl -X POST http://localhost:8080/oauth/token \
  -H "Authorization: Basic {base64(client_id:client_secret)}" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "refresh_token",
    "refresh_token": "{refresh_token}"
  }'
```

### Testing OAuth2

A test script is provided:
```bash
# Without OAuth2 (default)
./test-oauth2-mcp.coffee

# With OAuth2 enabled
ENABLE_OAUTH2=true ./test-oauth2-mcp.coffee
```

## Security Considerations

- The MCP endpoint inherits ClodForest's CORS configuration
- When OAuth2 is disabled (default), no authentication is required
- When OAuth2 is enabled, all MCP requests require a valid Bearer token with 'mcp' scope
- OAuth2 tokens are stored in memory (use a database for production)
- Demo credentials for testing: admin/admin (change in production!)
- All operations are subject to ClodForest's security policies
- Git operations are limited to whitelisted commands when enabled
