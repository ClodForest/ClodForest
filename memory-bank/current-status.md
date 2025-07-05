# ClodForest OAuth2 + MCP Server Implementation Status

## Current Status: OIDC-PROVIDER MIGRATION BLOCKED ❌

**Migration from oauth2-server to oidc-provider blocked by MCP Inspector compatibility**

### Current Task Progress:

#### Issue Encountered:
- ❌ **MCP Inspector Compatibility Issue** - oidc-provider has hardcoded validation that rejects `refresh_token` in grant_types array
- ❌ **Error**: "grant_types can only contain 'authorization_code' or 'client_credentials'"
- ❌ **Root Cause**: oidc-provider enforces strict RFC 7591 compliance that conflicts with MCP Inspector's registration request
- ❌ **Multiple Fix Attempts Failed**: Middleware filtering, extraClientMetadata validation, removing refresh_token from supported grants

#### Analysis:
- **oidc-provider validation is too strict** - It doesn't allow `refresh_token` in grant_types during registration
- **MCP Inspector expects refresh_token support** - Sends `["authorization_code", "refresh_token"]` in registration
- **RFC 6749 allows this pattern** - refresh_token can be explicitly requested in grant_types
- **oidc-provider interpretation differs** - Treats refresh_token as implicit with authorization_code

#### Files Modified During Migration:
- ✅ `src/oauth/oidc-provider.coffee` - New oidc-provider configuration with file-based adapter
- ✅ `src/oauth/router.coffee` - Updated to use oidc-provider instead of oauth2-server
- ✅ `src/middleware/auth.coffee` - Updated for oidc-provider token introspection
- ✅ `src/app.coffee` - Updated to use new oidc-provider router
- ✅ `memory-bank/development-practices.md` - Added development workflow guidelines

#### Technical Details:
- **Library**: Migrating from `oauth2-server` to `oidc-provider` v8.x
- **Adapter**: Custom file-based adapter for persistence (FileAdapter class)
- **Grant Types**: authorization_code, client_credentials, refresh_token
- **Issue**: MCP Inspector sends `["authorization_code", "refresh_token"]` but oidc-provider expects only `["authorization_code"]`

#### Next Steps to Resolve:
1. **Research oidc-provider documentation** for proper refresh_token handling
2. **Implement custom validation policy** to filter refresh_token from grant_types during registration
3. **Test with MCP Inspector** to verify compatibility
4. **Ensure backward compatibility** with existing OAuth2 flows

### Previous Implementation (Still Working):

#### Core Application:
- ✅ `src/app.coffee` - Main Express application with proper CoffeeScript structure
- ✅ `package.json` - Updated to use CoffeeScript entry point and scripts

#### Security & Middleware:
- ✅ `src/middleware/security.coffee` - Helmet security headers and HTTPS enforcement
- ✅ `src/middleware/auth.coffee` - OAuth2 authentication middleware with scope verification

#### OAuth2 Implementation (Original):
- ✅ `src/oauth/model.coffee` - File system persistence for OAuth2 data (clients/tokens)
- ✅ `src/oauth/server.coffee` - OAuth2 server with client registration, token, and introspection endpoints

#### Routes & Endpoints:
- ✅ `src/routes/wellknown.coffee` - RFC 5785 well-known endpoints for OAuth2 and MCP discovery
- ✅ `src/routes/health.coffee` - Health check endpoints (/, /ready, /live)

#### MCP Implementation:
- ✅ `src/mcp/server.coffee` - MCP 2025-06-18 compliant server with JSON-RPC 2.0 over HTTP
- ✅ `src/mcp/tools/state.coffee` - Three state directory tools with security validation

### Coding Standards Applied:
- ✅ **CoffeeScript language** - All files converted from JavaScript
- ✅ **Vertical alignment** - Related imports and assignments aligned
- ✅ **Filename tagging** - All files have proper FILENAME comments
- ✅ **Node.js module prefixes** - Using node:path, node:fs/promises, node:crypto
- ✅ **Define-after-use pattern** - Functions defined after first use
- ✅ **Export pattern** - Using module.exports.foo = foo = pattern where appropriate

### Architecture (Target):

```
Express App (src/app.coffee)
├── Security Middleware (helmet, HTTPS redirect)
├── CORS & Body Parsing
├── Well-known endpoints (/.well-known/*)
├── Health endpoints (/api/health/*)
├── OIDC Provider endpoints (/oauth/*)
│   ├── /register - Client registration (RFC 7591) [oidc-provider]
│   ├── /token - Token endpoint (RFC 6749) [oidc-provider]
│   ├── /authorize - Authorization endpoint [oidc-provider]
│   └── /introspect - Token introspection (RFC 7662) [oidc-provider]
└── MCP endpoint (/api/mcp) [OAuth2 protected]
    └── Three state management tools:
        ├── read_state_file
        ├── write_state_file
        └── list_state_files
```

### Security Features:
- ✅ **OAuth2 Bearer token authentication** for MCP endpoint
- ✅ **Path validation** to prevent directory traversal attacks
- ✅ **Scope checking** (mcp, read, write scopes)
- ✅ **HTTPS enforcement** in production
- ✅ **Security headers** via Helmet
- ✅ **File system access restricted** to state/ directory only

### RFC Compliance (Target):
- ✅ **RFC 6749** - OAuth 2.0 Authorization Framework
- ✅ **RFC 6750** - Bearer Token Usage
- 🔄 **RFC 7591** - Dynamic Client Registration (stricter validation with oidc-provider)
- ✅ **RFC 7662** - Token Introspection
- ✅ **RFC 8414** - Authorization Server Metadata
- ✅ **RFC 8707** - Resource Indicators
- ✅ **MCP 2025-06-18** - Model Context Protocol specification

### State Tools Functionality:
1. **read_state_file(path)** - Securely read files from state/ directory
2. **write_state_file(path, content)** - Securely write files to state/ directory  
3. **list_state_files(path)** - List directory contents with file metadata

### Current Server Status:
- 🔄 **Server Running**: localhost:8080 with oidc-provider implementation
- ❌ **MCP Inspector Test**: Failing due to grant_types validation
- ✅ **Basic Endpoints**: Health checks working
- 🔄 **OAuth2 Endpoints**: oidc-provider endpoints active but incompatible with MCP Inspector

### Test Results (Current):
- ❌ **MCP Inspector Client Registration**: Status 400 - grant_types validation error
- 🔄 **Basic MCP Functionality**: Not tested yet (blocked by registration)
- 🔄 **Comprehensive Tool Testing**: Not tested yet (blocked by registration)
- 🔄 **Security Boundary Testing**: Not tested yet (blocked by registration)
- 🔄 **RFC 8414 Compliance**: Not tested yet (blocked by registration)

### Development Practices Established:
- ✅ **Development workflow documented** in memory-bank/development-practices.md
- ✅ **Server management**: Use npm run kill/start, check logs/ directory
- ✅ **Syntax validation**: Use coffee -c before testing
- ✅ **Research-first approach**: Look up documentation instead of guessing

### Immediate Next Actions:
1. **Research oidc-provider refresh_token handling** - Find proper way to support refresh tokens
2. **Implement grant_types filtering** - Remove refresh_token from registration, add implicitly
3. **Test MCP Inspector compatibility** - Verify registration works after fix
4. **Run full test suite** - Ensure all existing functionality still works
5. **Update production deployment** - Once compatibility is confirmed

### Migration Benefits (When Complete):
- **Better RFC compliance** - oidc-provider is more standards-compliant
- **Maintained functionality** - All existing OAuth2 flows preserved
- **Enhanced validation** - Stricter input validation and error handling
- **Future-proof** - Better foundation for additional OAuth2/OIDC features

**Status: OIDC-PROVIDER MIGRATION 80% COMPLETE - RESOLVING MCP INSPECTOR COMPATIBILITY**

### Production URLs (Previous Working Version):
- **Base URL**: https://clodforest.thatsnice.org
- **OAuth2 Discovery**: https://clodforest.thatsnice.org/.well-known/oauth-authorization-server
- **MCP Discovery**: https://clodforest.thatsnice.org/.well-known/mcp-server
- **MCP Endpoint**: https://clodforest.thatsnice.org/api/mcp (OAuth2 protected)
- **Health Check**: https://clodforest.thatsnice.org/api/health

### Documentation & Quality Standards:
Reference documentation in `docs/` directory:
- **`state/contexts/domains/coding_standard.md`**
- **`state/contexts/domains/general_development.yaml`** 
- **`memory-bank/development-practices.md`** - New development workflow guidelines
