# FILENAME: { ClodForest/docs/rfc_compliance_testing.md }
# RFC Compliance Testing Documentation

## Overview

ClodForest now includes comprehensive RFC compliance testing to ensure adherence to all relevant internet standards. The test scripts validate compliance with multiple RFCs that govern OAuth2, MCP, and web service discovery protocols.

## Test Scripts

### 1. RFC 5785 Well-Known URIs (`bin/test-well-known.coffee`)

Tests compliance with RFC 5785 - "Defining Well-Known Uniform Resource Identifiers (URIs)"

**What it tests:**
- `/.well-known/oauth-authorization-server` endpoint (RFC 8414)
- `/.well-known/mcp-server` endpoint (ClodForest extension)
- Proper Content-Type headers (`application/json`)
- CORS headers for cross-origin discovery
- JSON format validation
- Required metadata fields per RFC specifications

**Usage:**
```bash
coffee bin/test-well-known.coffee [--verbose] [--env production]
```

**Exit codes:**
- `0`: RFC 5785 compliance verified
- `1`: RFC 5785 compliance failure

### 2. RFC 6749 OAuth 2.0 Authorization Framework (`bin/test-oauth2.coffee`)

Tests comprehensive OAuth2 compliance according to RFC 6749, RFC 6750, and RFC 8414.

**What it tests:**
- Client registration (RFC 6749 Section 2)
- Client credentials grant (RFC 6749 Section 4.4)
- Authorization code grant (RFC 6749 Section 4.1) [with --all-grants]
- Token endpoint validation (RFC 6749 Section 3.2)
- Bearer token usage (RFC 6750)
- Error response formats (RFC 6749 Section 5.2)
- Well-known discovery (RFC 8414)

**Usage:**
```bash
coffee bin/test-oauth2.coffee [--verbose] [--all-grants] [--env production]
```

**Exit codes:**
- `0`: RFC 6749 compliance verified
- `1`: RFC 6749 compliance failure

### 3. MCP 2025-06-18 Specification (`bin/test-mcp.coffee`)

Tests comprehensive MCP protocol compliance according to JSON-RPC 2.0 and HTTP transport requirements.

**What it tests:**
- Protocol version validation (2025-06-18)
- JSON-RPC 2.0 format compliance
- HTTP transport requirements
- Initialize method compliance
- Capability negotiation
- Tools capability validation
- Tools list/call operations
- Server info validation
- Error handling compliance

**Usage:**
```bash
coffee bin/test-mcp.coffee [--verbose] [--auth] [--env production]
```

**Exit codes:**
- `0`: Full MCP compliance verified
- `1`: Compliance failure or error

### 4. OAuth2 + MCP Integration (`bin/test-oauth2-mcp.coffee`)

Tests end-to-end integration compliance between OAuth2 and MCP protocols.

**What it tests:**
- Complete OAuth2 + MCP workflow
- Cross-protocol authentication
- Integration compliance
- End-to-end functionality

**Usage:**
```bash
coffee bin/test-oauth2-mcp.coffee
```

### 5. Comprehensive Test Runner (`bin/test-all-rfcs.coffee`)

Orchestrates all RFC compliance tests and provides a comprehensive compliance report.

**What it does:**
- Runs all test suites sequentially
- Provides detailed compliance reporting
- Calculates overall compliance percentage
- Identifies specific compliance gaps

**Usage:**
```bash
coffee bin/test-all-rfcs.coffee [--verbose] [--env production]
```

**Exit codes:**
- `0`: All RFC compliance tests passed
- `1`: One or more RFC compliance tests failed

## RFC Standards Covered

### RFC 5785 - Well-Known URIs
- **Purpose**: Standardizes discovery endpoints for web services
- **Implementation**: `/.well-known/` path prefix for metadata endpoints
- **ClodForest Usage**: OAuth2 and MCP service discovery

### RFC 6749 - OAuth 2.0 Authorization Framework
- **Purpose**: Defines OAuth2 authorization flows and security requirements
- **Grant Types**: Client credentials, authorization code, implicit, resource owner password
- **ClodForest Usage**: API authentication and authorization

### RFC 6750 - Bearer Token Usage
- **Purpose**: Defines how to use bearer tokens in HTTP requests
- **Implementation**: `Authorization: Bearer <token>` header format
- **ClodForest Usage**: API request authentication

### RFC 8414 - OAuth Authorization Server Metadata
- **Purpose**: Standardizes OAuth2 server metadata discovery
- **Implementation**: `/.well-known/oauth-authorization-server` endpoint
- **ClodForest Usage**: Client configuration and capability discovery

### JSON-RPC 2.0
- **Purpose**: Defines remote procedure call protocol over JSON
- **Implementation**: Request/response format, error handling, notifications
- **ClodForest Usage**: MCP protocol transport layer

### MCP 2025-06-18
- **Purpose**: Model Context Protocol for AI assistant integration
- **Implementation**: Tools, resources, prompts, capability negotiation
- **ClodForest Usage**: AI assistant API interface

## Test Environment Configuration

### Local Environment (default)
```
Host: localhost
Port: 8080
Protocol: HTTP
Endpoints: /api/mcp, /oauth/*, /.well-known/*
```

### Production Environment
```
Host: clodforest.thatsnice.org
Port: 443
Protocol: HTTPS
Endpoints: /api/mcp, /oauth/*, /.well-known/*
```

## Compliance Validation

### What Constitutes Compliance

1. **Protocol Adherence**: Exact compliance with RFC specifications
2. **Error Handling**: Proper error response formats and codes
3. **Security Requirements**: HTTPS, proper authentication, CORS headers
4. **Metadata Formats**: Valid JSON structures with required fields
5. **HTTP Transport**: Correct status codes, headers, and content types

### Compliance Scoring

Tests use strict pass/fail criteria:
- **PASS**: 100% compliance with RFC requirements
- **FAIL**: Any deviation from RFC specifications

No partial credit or fallback modes - only true compliance is accepted.

## Integration with Development Workflow

### Test-Driven Development (TDD)
1. Tests define RFC compliance requirements
2. Implementation must pass all tests
3. No deployment until full compliance achieved

### Continuous Integration
```bash
# Run all RFC compliance tests
npm run test:rfc

# Or run individual test suites
npm run test:well-known
npm run test:oauth2
npm run test:mcp
npm run test:integration
```

### Pre-deployment Validation
```bash
# Validate production readiness
coffee bin/test-all-rfcs.coffee --env production --verbose
```

## Troubleshooting

### Common Issues

1. **Server Not Running**
   - Ensure ClodForest server is started
   - Check port availability (8080 for local, 443 for production)

2. **OAuth2 Not Enabled**
   - Set `OAUTH2_AUTH=true` environment variable
   - Restart server after configuration change

3. **Missing Endpoints**
   - Implement required `/.well-known/` endpoints
   - Add OAuth2 infrastructure (`/oauth/*` endpoints)

4. **Authentication Failures**
   - Verify OAuth2 client registration works
   - Check token generation and validation

### Debug Mode

Run tests with `--verbose` flag for detailed output:
```bash
coffee bin/test-all-rfcs.coffee --verbose
```

## Future Enhancements

### Additional RFCs to Consider
- RFC 7662 - OAuth Token Introspection
- RFC 8693 - OAuth Token Exchange
- RFC 9068 - JSON Web Token (JWT) Profile for OAuth 2.0 Access Tokens

### Test Coverage Expansion
- Performance testing under load
- Security penetration testing
- Cross-browser compatibility testing
- Mobile client testing

## Conclusion

The RFC compliance testing framework ensures ClodForest adheres to internet standards, providing:

1. **Interoperability**: Works with standard OAuth2 and MCP clients
2. **Security**: Follows established security best practices
3. **Reliability**: Predictable behavior according to specifications
4. **Maintainability**: Clear compliance requirements for future development

All test scripts follow Robert's collaboration style with proper error handling, comprehensive logging, and clear success/failure criteria.
