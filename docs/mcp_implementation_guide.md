# ClodForest MCP Migration Implementation Guide

**Target**: Transform ClodForest from custom REST to industry-standard MCP server  
**Approach**: Extend existing Express.js app with `/mcp/*` and `/oauth/*` routes  
**Timeline**: 3-4 hours total implementation  
**Compatibility**: Maintain v0 REST API during migration

---

## Architecture Overview

### Integration Strategy
- **Hybrid API**: v0 REST + v1 MCP in same Express app
- **Backward Compatibility**: Existing clients continue working
- **Context Reuse**: Share ClodForest context logic between v0/v1
- **OAuth2**: Dynamic Client Registration (RFC 7591) for Claude Desktop

### Project Structure
```
src/coordinator/
├── index.coffee              # Main Express app (existing)
├── handlers/                 # v0 REST handlers (existing)
├── lib/                      # Shared ClodForest logic (existing)
├── mcp/                      # New MCP implementation
│   ├── server.js            # MCP JSON-RPC server core
│   ├── capabilities.js      # MCP capability handlers
│   ├── oauth.js             # OAuth2 Dynamic Client Registration
│   └── transport.js         # HTTP/SSE transport layer
└── routes/                   # New Express route handlers
    ├── mcp.js               # /mcp/* route handlers
    └── oauth.js             # /oauth/* route handlers
```

---

## Implementation Phases

### Phase 1: Dependencies and Setup (15 minutes)

#### Install Required Packages
```bash
# From ClodForest project root
cd src/coordinator
npm install --save @modelcontextprotocol/sdk jsonrpc-lite uuid cors
npm install --save-dev @types/uuid
```

#### File: `src/coordinator/mcp/server.js`
```javascript
// src/coordinator/mcp/server.js
import { Server }           from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema,
         ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { z }                from 'zod';

import { MCP_CAPABILITIES } from './capabilities.js';

class ClodForestMCPServer {
  constructor(clodForestLib) {
    this.clodForest = clodForestLib;
    this.server     = new Server(
      {
        name    : 'clodforest-mcp-server',
        version : '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: Object.values(MCP_CAPABILITIES).map(cap => ({
        name        : cap.name,
        description : cap.description,
        inputSchema : cap.inputSchema,
      })),
    }));

    // Execute tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      
      const capability = MCP_CAPABILITIES[name];
      if (!capability) {
        throw new Error(`Unknown tool: ${name}`);
      }

      return await capability.handler(args, this.clodForest);
    });
  }

  async start(transport) {
    await this.server.connect(transport);
  }
}

export { ClodForestMCPServer };

// Data structures and constants
const MCP_TOOL_NAMES = [
  'get_context',
  'set_context', 
  'list_contexts',
  'inherit_context',
  'search_contexts',
];

export { MCP_TOOL_NAMES };
```

### Phase 2: MCP Capabilities (45 minutes)

#### File: `src/coordinator/mcp/capabilities.js`
```javascript
// src/coordinator/mcp/capabilities.js
import { z } from 'zod';

// Core capability handlers that bridge MCP to ClodForest logic
const MCP_CAPABILITIES = {
  get_context: {
    name        : 'get_context',
    description : 'Retrieve context data by name with inheritance resolution',
    inputSchema : {
      type      : 'object',
      properties: {
        name: {
          type        : 'string',
          description : 'Context name (e.g., "robert-identity", "collaboration-patterns")',
        },
        resolve_inheritance: {
          type        : 'boolean',
          description : 'Whether to resolve context inheritance chains',
          default     : true,
        },
      },
      required: ['name'],
    },
    handler: async (args, clodForest) => {
      const context = await clodForest.context.get(args.name, {
        resolveInheritance: args.resolve_inheritance ?? true,
      });
      
      return {
        content: [{
          type: 'text',
          text: `Context: ${args.name}\n\n${context.content}`,
        }],
      };
    },
  },

  set_context: {
    name        : 'set_context',
    description : 'Create or update context data',
    inputSchema : {
      type      : 'object', 
      properties: {
        name: {
          type        : 'string',
          description : 'Context name to create/update',
        },
        content: {
          type        : 'string',
          description : 'Context content (YAML format preferred)',
        },
        inherits: {
          type        : 'array',
          items       : { type: 'string' },
          description : 'List of parent contexts to inherit from',
        },
      },
      required: ['name', 'content'],
    },
    handler: async (args, clodForest) => {
      await clodForest.context.set(args.name, {
        content : args.content,
        inherits: args.inherits || [],
      });
      
      return {
        content: [{
          type: 'text', 
          text: `Successfully updated context: ${args.name}`,
        }],
      };
    },
  },

  list_contexts: {
    name        : 'list_contexts',
    description : 'List all available contexts with metadata',
    inputSchema : {
      type      : 'object',
      properties: {
        category: {
          type        : 'string',
          description : 'Filter by category (core, domains, projects)',
        },
      },
    },
    handler: async (args, clodForest) => {
      const contexts = await clodForest.context.list(args.category);
      
      const contextList = contexts.map(ctx => 
        `- ${ctx.name} (${ctx.category}) - ${ctx.description || 'No description'}`
      ).join('\n');
      
      return {
        content: [{
          type: 'text',
          text: `Available Contexts:\n\n${contextList}`,
        }],
      };
    },
  },

  inherit_context: {
    name        : 'inherit_context', 
    description : 'Create new context that inherits from existing contexts',
    inputSchema : {
      type      : 'object',
      properties: {
        name: {
          type        : 'string',
          description : 'New context name',
        },
        parents: {
          type        : 'array',
          items       : { type: 'string' },
          description : 'Parent contexts to inherit from',
        },
        content: {
          type        : 'string',
          description : 'Additional content for this context',
        },
      },
      required: ['name', 'parents'],
    },
    handler: async (args, clodForest) => {
      const result = await clodForest.context.inherit(args.name, {
        parents : args.parents,
        content : args.content || '',
      });
      
      return {
        content: [{
          type: 'text',
          text: `Created inherited context: ${args.name}\nInherits from: ${args.parents.join(', ')}`,
        }],
      };
    },
  },

  search_contexts: {
    name        : 'search_contexts',
    description : 'Search context content and metadata',
    inputSchema : {
      type      : 'object',
      properties: {
        query: {
          type        : 'string', 
          description : 'Search query string',
        },
        limit: {
          type        : 'number',
          description : 'Maximum number of results',
          default     : 10,
        },
      },
      required: ['query'],
    },
    handler: async (args, clodForest) => {
      const results = await clodForest.context.search(args.query, {
        limit: args.limit || 10,
      });
      
      const resultText = results.map(result =>
        `## ${result.name}\nScore: ${result.score}\n${result.excerpt}...\n`
      ).join('\n');
      
      return {
        content: [{
          type: 'text',
          text: `Search Results for "${args.query}":\n\n${resultText}`,
        }],
      };
    },
  },
};

export { MCP_CAPABILITIES };
```

### Phase 3: OAuth2 Dynamic Client Registration (30 minutes)

#### File: `src/coordinator/mcp/oauth.js`
```javascript
// src/coordinator/mcp/oauth.js
import { randomUUID }     from 'node:crypto';
import { readFile,
         writeFile }      from 'node:fs/promises';
import { join }           from 'node:path';

class OAuth2ClientRegistry {
  constructor(dataDir = './data/oauth') {
    this.dataDir     = dataDir;
    this.clients     = new Map();
    this.accessTokens = new Map();
  }

  async initialize() {
    try {
      const clientsData = await readFile(join(this.dataDir, 'clients.json'), 'utf8');
      const clients     = JSON.parse(clientsData);
      
      for (const [clientId, clientData] of Object.entries(clients)) {
        this.clients.set(clientId, clientData);
      }
    } catch (error) {
      // File doesn't exist yet, start with empty registry
      console.log('OAuth client registry starting fresh');
    }
  }

  async registerClient(registrationRequest) {
    const clientId     = randomUUID();
    const clientSecret = randomUUID();
    
    const clientInfo = {
      client_id     : clientId,
      client_secret : clientSecret,
      client_name   : registrationRequest.client_name || 'Claude Desktop',
      redirect_uris : registrationRequest.redirect_uris || [],
      grant_types   : ['authorization_code', 'client_credentials'],
      response_types: ['code'],
      scope         : 'mcp:access',
      created_at    : new Date().toISOString(),
    };

    this.clients.set(clientId, clientInfo);
    await this.persistClients();

    return {
      client_id                : clientId,
      client_secret           : clientSecret,
      client_id_issued_at     : Math.floor(Date.now() / 1000),
      client_secret_expires_at: 0, // Never expires
    };
  }

  async validateClient(clientId, clientSecret) {
    const client = this.clients.get(clientId);
    return client && client.client_secret === clientSecret;
  }

  async generateAccessToken(clientId, scope = 'mcp:access') {
    const accessToken = randomUUID();
    const expiresAt   = Date.now() + (3600 * 1000); // 1 hour

    this.accessTokens.set(accessToken, {
      client_id : clientId,
      scope     : scope,
      expires_at: expiresAt,
    });

    return {
      access_token: accessToken,
      token_type  : 'Bearer',
      expires_in  : 3600,
      scope       : scope,
    };
  }

  async validateAccessToken(token) {
    const tokenData = this.accessTokens.get(token);
    
    if (!tokenData) return false;
    if (tokenData.expires_at < Date.now()) {
      this.accessTokens.delete(token);
      return false;
    }
    
    return tokenData;
  }

  async persistClients() {
    const clientsData = Object.fromEntries(this.clients);
    await writeFile(
      join(this.dataDir, 'clients.json'),
      JSON.stringify(clientsData, null, 2)
    );
  }
}

export { OAuth2ClientRegistry };
```

### Phase 4: HTTP Transport Routes (30 minutes)

#### File: `src/coordinator/routes/mcp.js`
```javascript
// src/coordinator/routes/mcp.js
import express        from 'express';
import { JSONRPCServer } from 'json-rpc-2.0';

import { MCP_CAPABILITIES } from '../mcp/capabilities.js';

function createMCPRoutes(clodForest, oauth) {
  const router = express.Router();
  
  // JSON-RPC server for MCP protocol
  const jsonRpcServer = new JSONRPCServer();

  // Register MCP methods
  jsonRpcServer.addMethod('tools/list', async () => ({
    tools: Object.values(MCP_CAPABILITIES).map(cap => ({
      name        : cap.name,
      description : cap.description,
      inputSchema : cap.inputSchema,
    })),
  }));

  jsonRpcServer.addMethod('tools/call', async (params) => {
    const { name, arguments: args } = params;
    
    const capability = MCP_CAPABILITIES[name];
    if (!capability) {
      throw new Error(`Unknown tool: ${name}`);
    }

    return await capability.handler(args, clodForest);
  });

  // OAuth middleware for MCP routes
  const requireAuth = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const token     = authHeader.slice(7);
    const tokenData = await oauth.validateAccessToken(token);
    
    if (!tokenData) {
      return res.status(401).json({ error: 'Invalid or expired access token' });
    }

    req.oauth = tokenData;
    next();
  };

  // MCP JSON-RPC endpoint
  router.post('/jsonrpc', requireAuth, async (req, res) => {
    try {
      const response = await jsonRpcServer.receive(req.body);
      if (response) {
        res.json(response);
      } else {
        res.status(204).end();
      }
    } catch (error) {
      console.error('MCP JSON-RPC error:', error);
      res.status(500).json({
        jsonrpc: '2.0',
        error  : {
          code   : -32603,
          message: 'Internal error',
        },
      });
    }
  });

  // Server-Sent Events endpoint for real-time updates
  router.get('/events', requireAuth, (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    // Send initial connection event
    res.write(`data: ${JSON.stringify({
      type: 'connected',
      timestamp: new Date().toISOString(),
    })}\n\n`);

    // Keep connection alive
    const heartbeat = setInterval(() => {
      res.write(`data: ${JSON.stringify({
        type: 'heartbeat',
        timestamp: new Date().toISOString(),
      })}\n\n`);
    }, 30000);

    req.on('close', () => {
      clearInterval(heartbeat);
    });
  });

  return router;
}

export { createMCPRoutes };
```

#### File: `src/coordinator/routes/oauth.js`
```javascript
// src/coordinator/routes/oauth.js
import express from 'express';

function createOAuthRoutes(oauth) {
  const router = express.Router();

  // Dynamic Client Registration (RFC 7591)
  router.post('/register', async (req, res) => {
    try {
      const clientInfo = await oauth.registerClient(req.body);
      res.status(201).json(clientInfo);
    } catch (error) {
      console.error('OAuth registration error:', error);
      res.status(400).json({
        error            : 'invalid_client_metadata',
        error_description: error.message,
      });
    }
  });

  // Token endpoint for Client Credentials flow
  router.post('/token', async (req, res) => {
    try {
      const { grant_type, client_id, client_secret, scope } = req.body;
      
      if (grant_type !== 'client_credentials') {
        return res.status(400).json({
          error            : 'unsupported_grant_type',
          error_description: 'Only client_credentials grant type is supported',
        });
      }

      const isValid = await oauth.validateClient(client_id, client_secret);
      if (!isValid) {
        return res.status(401).json({
          error            : 'invalid_client',
          error_description: 'Invalid client credentials',
        });
      }

      const tokenResponse = await oauth.generateAccessToken(client_id, scope);
      res.json(tokenResponse);
      
    } catch (error) {
      console.error('OAuth token error:', error);
      res.status(500).json({
        error            : 'server_error',
        error_description: 'Internal server error',
      });
    }
  });

  // Well-known configuration endpoint
  router.get('/.well-known/oauth-authorization-server', (req, res) => {
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    
    res.json({
      issuer                           : baseUrl,
      registration_endpoint           : `${baseUrl}/oauth/register`,
      token_endpoint                  : `${baseUrl}/oauth/token`,
      grant_types_supported           : ['client_credentials'],
      token_endpoint_auth_methods_supported: ['client_secret_basic', 'client_secret_post'],
      scopes_supported                : ['mcp:access'],
    });
  });

  return router;
}

export { createOAuthRoutes };
```

### Phase 5: Express App Integration (20 minutes)

#### Modify: `src/coordinator/index.coffee`
```coffeescript
# Add these imports at the top
{ createMCPRoutes }   = require './routes/mcp.js'
{ createOAuthRoutes } = require './routes/oauth.js' 
{ OAuth2ClientRegistry } = require './mcp/oauth.js'

# Add after existing middleware setup
setupMCPIntegration = (app, clodForest) ->
  # Initialize OAuth2 client registry
  oauth = new OAuth2ClientRegistry('./data/oauth')
  await oauth.initialize()
  
  # Add CORS for MCP clients
  app.use '/mcp', cors()
  app.use '/oauth', cors()
  
  # Mount MCP and OAuth routes
  app.use '/mcp', createMCPRoutes(clodForest, oauth)
  app.use '/oauth', createOAuthRoutes(oauth)
  
  console.log 'MCP and OAuth2 endpoints initialized'
  console.log '  - POST /oauth/register (Dynamic Client Registration)'
  console.log '  - POST /oauth/token (Client Credentials flow)'
  console.log '  - POST /mcp/jsonrpc (MCP JSON-RPC endpoint)'
  console.log '  - GET  /mcp/events (Server-Sent Events)'

# Call in main app setup (after clodForest is initialized)
await setupMCPIntegration(app, clodForest)
```

### Phase 6: Testing and Validation (30 minutes)

#### OAuth2 Registration Test
```bash
# Register a new OAuth2 client
curl -X POST http://localhost:3000/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Claude Desktop",
    "redirect_uris": ["http://localhost"]
  }'

# Expected response:
# {
#   "client_id": "uuid-here",
#   "client_secret": "uuid-here", 
#   "client_id_issued_at": 1234567890,
#   "client_secret_expires_at": 0
# }
```

#### Access Token Test
```bash
# Get access token (replace client_id and client_secret)
curl -X POST http://localhost:3000/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "your-client-id",
    "client_secret": "your-client-secret"
  }'

# Expected response:
# {
#   "access_token": "uuid-here",
#   "token_type": "Bearer",
#   "expires_in": 3600,
#   "scope": "mcp:access"
# }
```

#### MCP JSON-RPC Test
```bash
# List available tools (replace YOUR_ACCESS_TOKEN)
curl -X POST http://localhost:3000/mcp/jsonrpc \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'

# Get context (replace YOUR_ACCESS_TOKEN)
curl -X POST http://localhost:3000/mcp/jsonrpc \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "jsonrpc": "2.0", 
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "get_context",
      "arguments": {
        "name": "robert-identity"
      }
    }
  }'
```

#### Claude Desktop Configuration
```json
{
  "mcpServers": {
    "clodforest": {
      "command": "node",
      "args": ["-e", "
        const oauth = await fetch('http://localhost:3000/oauth/register', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ client_name: 'Claude Desktop' })
        }).then(r => r.json());
        
        const token = await fetch('http://localhost:3000/oauth/token', {
          method: 'POST', 
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            grant_type: 'client_credentials',
            client_id: oauth.client_id,
            client_secret: oauth.client_secret
          })
        }).then(r => r.json());
        
        console.log('Bearer ' + token.access_token);
      "],
      "env": {
        "MCP_SERVER_URL": "http://localhost:3000/mcp/jsonrpc"
      }
    }
  }
}
```

---

## Success Validation Checklist

- [ ] **Dependencies installed**: MCP SDK and supporting packages
- [ ] **OAuth2 working**: Can register clients and get access tokens
- [ ] **MCP JSON-RPC**: Tools list and call endpoints responding
- [ ] **Authentication**: Bearer tokens required and validated
- [ ] **Context integration**: ClodForest contexts accessible via MCP
- [ ] **Claude Desktop**: Can connect and use ClodForest tools
- [ ] **Backward compatibility**: v0 REST API still functional
- [ ] **Error handling**: Proper JSON-RPC error responses

---

## Troubleshooting

### Common Issues

**OAuth Registration Fails**
- Check `./data/oauth/` directory exists and is writable
- Verify Express app has CORS middleware for `/oauth/*` routes

**MCP JSON-RPC Errors**
- Validate JSON-RPC 2.0 format (requires `jsonrpc: "2.0"` field)
- Check Bearer token format: `Authorization: Bearer <token>`
- Verify tool names match exactly (case-sensitive)

**Context Access Issues**
- Ensure ClodForest context system is initialized
- Check file permissions on `state/contexts/` directory
- Validate YAML syntax in context files

**Claude Desktop Connection**
- Verify server is running on correct port (default 3000)
- Check OAuth2 well-known endpoint: `GET /oauth/.well-known/oauth-authorization-server`
- Ensure firewall allows localhost connections

### Debug Commands

```bash
# Check server health
curl http://localhost:3000/health

# Test OAuth well-known config
curl http://localhost:3000/oauth/.well-known/oauth-authorization-server

# Validate JSON-RPC format
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
  curl -X POST http://localhost:3000/mcp/jsonrpc \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer TOKEN" \
    -d @-
```

---

## Post-Implementation

### Documentation Updates
1. Update README.md with MCP endpoints
2. Add OAuth2 configuration examples  
3. Document context inheritance via MCP
4. Create Claude Desktop setup guide

### Production Considerations
- [ ] HTTPS certificate for OAuth2 security
- [ ] Rate limiting on OAuth endpoints
- [ ] Access token persistence across restarts
- [ ] Logging and monitoring for MCP usage
- [ ] Client revocation endpoints

### Future Enhancements
- [ ] Server-Sent Events for real-time context updates
- [ ] Batch operations for multiple context operations
- [ ] WebSocket transport option
- [ ] Advanced context search with filters
- [ ] Context version history tracking

---

This implementation transforms ClodForest into a premium MCP server while preserving all existing functionality. The hybrid v0/v1 API approach ensures smooth migration and backward compatibility.