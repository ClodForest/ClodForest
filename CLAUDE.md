# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Development Server
```bash
    # Start development server with auto-restart
    npm run dev
    
    # Start production server
    npm start
```
    
### Process Management
```bash
    # Check server status
    npm run status
    
    # Stop server
    npm run kill
    
    # View logs
    npm run logs
    npm run logs-follow
    
    # View specific logs
    tail -20 logs/app.log
    tail -20 logs/oauth.log
```

### Testing
```bash
    # Run all tests
    npm test
    
    # Run specific test suites
    coffee test/mcp-test.coffee
    coffee test/mcp-comprehensive-test.coffee
    coffee test/mcp-security-test.coffee
    coffee test/oauth-rfc-compliant-test.coffee
```

### CoffeeScript Development
```bash
    # Validate CoffeeScript syntax
    coffee -c filename.coffee
    
    # Watch files for changes (if nodemon is installed)
    npm run test:watch
```

### Build System (Cake)
```bash
    # View available tasks
    cake help
    
    # Initialize configuration
    cake setup
    
    # Run development server
    cake dev
    
    # Install as system service
    cake install
```

## Architecture Overview

ClodForest is a **context management and AI coordination system** that enables Claude instances to inherit, compose, and preserve complex contextual knowledge across sessions. The system consists of three main components:

### 1. Express Web Server (`src/app.coffee`)
- **Port**: 8080 (configurable via `process.env.PORT`)
- **Main endpoints**: OAuth2 (`/oauth/*`), MCP (`/api/mcp`), Health (`/api/health`), Well-known (`/.well-known/*`)
- **Middleware**: Security headers, CORS, request logging, authentication
- **Language**: CoffeeScript with vertical alignment coding standards

### 2. OAuth2/OIDC Provider (`src/oauth/`)
- **Provider**: Uses `oidc-provider` library for OAuth2 compliance
- **Storage**: File-based adapter (`FileAdapter`) storing in `data/oauth2/` directory
- **Grant Types**: `authorization_code`, `client_credentials`, `refresh_token`
- **Scopes**: `openid`, `mcp`, `read`, `write`
- **Special Features**: Auto-approval for MCP clients, MCP Inspector compatibility

### 3. MCP (Model Context Protocol) Server (`src/mcp/`)
- **Protocol**: JSON-RPC 2.0 over HTTP
- **Authentication**: OAuth2 Bearer tokens required
- **Tools**: `read_state_file`, `write_state_file`, `list_state_files`
- **State Directory**: `state/` contains context hierarchies and session data

## Key File Structure

```
src/
├── app.coffee               # Main Express application
├── lib/logger.coffee        # Logging utilities
├── middleware/
│   ├── auth.coffee          # OAuth2 authentication
│   └── security.coffee      # Security headers
├── oauth/
│   ├── oidc-provider.coffee # OAuth2/OIDC configuration
│   ├── router.coffee        # OAuth2 routes
│   └── model.coffee         # OAuth2 data models
├── mcp/
│   ├── server.coffee        # MCP protocol handler
│   └── tools/state.coffee   # State management tools
└── routes/
    ├── health.coffee        # Health check endpoints
    └── wellknown.coffee     # Well-known endpoints

state/                       # Context management system
├── contexts/
│   ├── core/                # Foundation contexts
│   ├── domains/             # Domain-specific contexts
│   └── projects/            # Project-specific contexts
├── instructions/            # Bootstrap and protocol definitions
└── transcripts/             # Archived conversations

data/oauth2/                 # OAuth2 persistence
├── Client.json
├── AuthorizationCode.json
└── tokens.json

test/                        # Comprehensive test suite
├── mcp-test.coffee
├── mcp-comprehensive-test.coffee
├── mcp-security-test.coffee
└── oauth-rfc-compliant-test.coffee
```

## Development Practices

### Server Management
- Use `npm run kill` followed by `npm run start` for clean restarts
- Check `logs/` directory files instead of using `tail -f` 
- Use `npm run logs` to view server output
- Validate CoffeeScript syntax with `coffee -c filename.coffee` before testing

### Code Quality Standards
- **Minimalism**:            Choose smaller solutions when equivalent options exist
- **Self-documenting code**: Avoid comments by making code clearer
- **Vertical alignment**:    Align related code to show relationships
- **Filename tagging**:      Include `# FILENAME: { ClodForest/path/file.coffee }` comments
- **Function definition**:   Define functions after their first use

### Testing Approach
- Make one change at a time and test rigorously
- Use comprehensive test suite covering MCP, OAuth2, and security
- Validate assumptions before proceeding
- Look up documentation instead of guessing at configurations

### Confidence and Claims
- **Qualified language**:      Use "appears to", "seems to", "might be" instead of definitive claims
- **Evidence-based claims**:   Don't declare problems "solved" until end-to-end verification
- **Flag assumptions**:        Clearly mark inferences vs. confirmed facts
- **Seek confirmation**:       Ask for verification before moving to next steps
- **Acknowledge uncertainty**: Be explicit about what you don't know or aren't sure about

## Context Management System

ClodForest implements a hierarchical context inheritance system:

- **Core contexts**:    Foundation identity, collaboration patterns, communication style
- **Domain contexts**:  Specialized modes (development, personal assistant, etc.)
- **Project contexts**: Specific project contexts with cross-references
- **Session handoffs**: Comprehensive time capsules for continuity

The system enables:
- **Modular loading**:             Load only needed contexts for current session
- **Cultural preservation**:       Maintain linguistic traditions and shared references
- **Multi-instance coordination**: Different Claude instances for different purposes
- **Persistent state**:            Context preservation across sessions

## API Integration

### MCP Protocol
- **Endpoint**:       `/api/mcp`
- **Authentication**: OAuth2 Bearer token required
- **Protocol**:       JSON-RPC 2.0
- **Tools**:          File operations within `state/` directory

### OAuth2 Endpoints
- **Registration**:  `/oauth/register`
- **Token**:         `/oauth/token`
- **Authorization**: `/oauth/authorize`
- **Introspection**: `/oauth/introspect`

### Health Monitoring
- **Health check**: `/api/health`
- **System status**: Includes OAuth2 and MCP component health

## Production Deployment

- **Environment**: AWS EC2 instance
- **Service management**: systemd, FreeBSD rc.d, or SysV init scripts
- **Process management**: Built-in start/stop/status scripts
- **Logging**: Structured logging to `logs/` directory
- **Configuration**: Environment variables and `config.yaml`

## Security Considerations

- **Path traversal protection**: MCP tools prevent directory traversal attacks
- **Authentication enforcement**: All MCP operations require valid OAuth2 tokens
- **CORS configuration**: Controlled origin access
- **Security headers**: Helmet.js security middleware
- **Error handling**: Sanitized error responses in production
