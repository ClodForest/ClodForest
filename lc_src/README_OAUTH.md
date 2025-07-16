# ClodForest OAuth2 DCR + MCP Server

This implements OAuth2 Dynamic Client Registration (RFC 7591) + OAuth 2.1 authentication for ClodForest MCP server, enabling Claude.ai remote access.

## Architecture

```
Claude.ai → OAuth2 DCR Server (port 8000) → MCP Server (port 8080)
                ↓ OAuth Flow
            [Client Registration]
            [Authorization Code] 
            [Token Exchange]
            [Authenticated MCP Proxy]
```

## Quick Start

### 1. Install Dependencies
```bash
cd /Users/robert/git/github/ClodForest/ClodForest/lc_src
pip install -r requirements.txt
```

### 2. Start Both Servers
```bash
python run_production.py
```

This starts:
- **MCP Server** on `localhost:8080` (direct access, local only)
- **OAuth DCR Server** on `localhost:8000` (Claude.ai endpoint)

### 3. Claude.ai Configuration
In Claude.ai MCP settings, use:
```
URL: http://your-server:8000/mcp
Authentication: OAuth2
```

## OAuth2 Endpoints

### Discovery
- `/.well-known/oauth-authorization-server` - RFC 8414 metadata
- `/.well-known/oauth-protected-resource/mcp` - MCP resource metadata

### OAuth Flow
- `POST /register` - RFC 7591 Dynamic Client Registration
- `GET /oauth/authorize` - Authorization endpoint
- `POST /oauth/token` - Token exchange endpoint

### MCP Access
- `/mcp/*` - OAuth-protected MCP proxy to port 8080

## Testing

### Local OAuth Flow Test
```bash
python test_oauth_flow.py
```

This simulates Claude.ai's complete OAuth flow:
1. Discovery endpoint check
2. Client registration  
3. Authorization code flow
4. Token exchange
5. Authenticated MCP call

### MCP Server Direct Test
```bash
python test_http_client.py
```

## Production Deployment

### AWS Configuration
Update `oauth_dcr_server.py` OAUTH_CONFIG for your domain:

```python
OAUTH_CONFIG = {
    "issuer": "https://your-domain.com",
    "authorization_endpoint": "https://your-domain.com/oauth/authorize",
    "token_endpoint": "https://your-domain.com/oauth/token",
    "registration_endpoint": "https://your-domain.com/register",
    # ... rest of config
}
```

### Systemd Service
Create `/etc/systemd/system/clodforest-oauth.service`:

```ini
[Unit]
Description=ClodForest OAuth2 DCR + MCP Server
After=network.target

[Service]
Type=exec
User=clodforest
WorkingDirectory=/path/to/ClodForest/lc_src
ExecStart=/usr/bin/python3 run_production.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Load Balancer Configuration
Route traffic:
- `/.well-known/*` → OAuth server port 8000
- `/oauth/*` → OAuth server port 8000  
- `/register` → OAuth server port 8000
- `/mcp` → OAuth server port 8000 (proxies to 8080)

## Security Notes

### Production Hardening Required
- **Persistent Storage**: Replace in-memory client/token storage with database
- **HTTPS Only**: All OAuth endpoints must use HTTPS in production
- **Secret Management**: Use environment variables for sensitive config
- **Rate Limiting**: Add rate limiting to registration and token endpoints
- **Token Expiration**: Implement proper token cleanup and refresh

### Current Implementation Status
- ✅ **RFC 7591 DCR Compliance**: Full Dynamic Client Registration
- ✅ **OAuth 2.1 Flow**: Authorization code with PKCE support
- ✅ **MCP Proxy**: Authenticated request forwarding
- ✅ **Discovery Endpoints**: Proper metadata exposure
- ⚠️  **In-Memory Storage**: Suitable for testing only
- ⚠️  **Auto-Approval**: No user consent screen (auto-approves Claude.ai)

## Debugging

### Check Registered Clients
```bash
curl http://localhost:8000/debug/clients
```

### Check Active Tokens  
```bash
curl http://localhost:8000/debug/tokens
```

### Health Check
```bash
# Standard health check
curl http://localhost:8000/health

# ALB health check (AWS Application Load Balancer)
curl http://localhost:8000/api/health
```

## Log Analysis

Common Claude.ai requests and expected responses:

```
GET /.well-known/oauth-authorization-server → 200 (OAuth metadata)
POST /register → 201 (client credentials)
GET /oauth/authorize → 302 (redirect with auth code)
POST /oauth/token → 200 (access token)
POST /mcp → 200 (proxied MCP response)
```

## Integration with Existing ClodForest

This OAuth wrapper preserves all existing ClodForest functionality:
- **MCP Tools**: `hello`, `list_contexts`, `read_context`, `search_contexts`, `write_context`
- **Context Directory**: Full access to `ClodForest/state/contexts/`
- **Backward Compatibility**: Direct MCP server still accessible on port 8080

The OAuth layer adds authentication without changing MCP functionality.
