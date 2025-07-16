#!/usr/bin/env python3
"""
ClodForest MCP Server with Integrated OAuth2 DCR
Single-port solution: MCP + OAuth2 Dynamic Client Registration
"""

import sys
import os
import secrets
import time
import hashlib
import base64
import logging
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

# Check Python version
if sys.version_info < (3, 9):
    print("Error: Python 3.9 or higher required")
    sys.exit(1)

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

from fastmcp import FastMCP

# Environment configuration
def get_config():
    """Get configuration from environment variables"""
    base_url = os.getenv("CLODFOREST_BASE_URL", "https://clodforest.thatsnice.org")
    return {
        "issuer": base_url,
        "authorization_endpoint": f"{base_url}/oauth/authorize",
        "token_endpoint": f"{base_url}/oauth/token",
        "registration_endpoint": f"{base_url}/register",
        "scopes_supported": ["mcp:read", "mcp:write"],
        "response_types_supported": ["code"],
        "grant_types_supported": ["authorization_code"],
        "token_endpoint_auth_methods_supported": ["client_secret_basic", "client_secret_post"],
        "code_challenge_methods_supported": ["S256"],
    }

# Data models for OAuth2 DCR
class ClientRegistrationRequest(BaseModel):
    """RFC 7591 Client Registration Request"""
    client_name: Optional[str] = None
    client_uri: Optional[str] = None
    logo_uri: Optional[str] = None
    scope: Optional[str] = None
    contacts: Optional[list[str]] = None
    tos_uri: Optional[str] = None
    policy_uri: Optional[str] = None
    jwks_uri: Optional[str] = None
    software_id: Optional[str] = None
    software_version: Optional[str] = None
    redirect_uris: Optional[list[str]] = None

class ClientRegistrationResponse(BaseModel):
    """RFC 7591 Client Registration Response"""
    client_id: str
    client_secret: str
    client_id_issued_at: int
    client_secret_expires_at: int
    client_name: Optional[str] = None
    client_uri: Optional[str] = None
    grant_types: list[str] = ["authorization_code"]
    response_types: list[str] = ["code"]
    scope: Optional[str] = None
    token_endpoint_auth_method: str = "client_secret_basic"
    redirect_uris: list[str] = []

class TokenRequest(BaseModel):
    """OAuth 2.1 Token Request"""
    grant_type: str
    code: Optional[str] = None
    redirect_uri: Optional[str] = None
    client_id: Optional[str] = None
    client_secret: Optional[str] = None
    code_verifier: Optional[str] = None

# Initialize MCP server and locate ClodForest state
mcp = FastMCP("ClodForest")
CONTEXT_DIR = Path(__file__).parent.parent / "state" / "contexts"
OAUTH_CONFIG = get_config()
DEBUG_MODE = os.getenv("CLODFOREST_DEBUG", "false").lower() == "true"

# Configure structured logging
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        # Add extra fields if present
        if hasattr(record, 'extra_fields'):
            log_entry.update(record.extra_fields)
            
        return json.dumps(log_entry)

# Setup multiple loggers
loggers = {}

def setup_logger(name: str, filename: str) -> logging.Logger:
    """Setup a JSON logger for specific log types"""
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    
    # Remove existing handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    # File handler with JSON formatter
    file_handler = logging.FileHandler(log_dir / filename)
    file_handler.setFormatter(JSONFormatter())
    logger.addHandler(file_handler)
    
    # Console handler for development
    if DEBUG_MODE:
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        ))
        logger.addHandler(console_handler)
    
    logger.propagate = False
    return logger

# Create specialized loggers
loggers['access'] = setup_logger('clodforest.access', 'access.log')
loggers['oauth'] = setup_logger('clodforest.oauth', 'oauth.log') 
loggers['mcp'] = setup_logger('clodforest.mcp', 'mcp.log')
loggers['error'] = setup_logger('clodforest.error', 'error.log')
loggers['app'] = setup_logger('clodforest.app', 'app.log')

def log_access(request: Any, response_code: int, **extra):
    """Log access requests in structured format"""
    loggers['access'].info("HTTP request", extra={
        'extra_fields': {
            'method': request.method,
            'path': str(request.url.path),
            'query': str(request.url.query) if request.url.query else None,
            'status_code': response_code,
            'client_ip': request.client.host if hasattr(request, 'client') else None,
            'user_agent': request.headers.get('user-agent'),
            **extra
        }
    })

def log_oauth(event: str, **data):
    """Log OAuth-specific events"""
    loggers['oauth'].info(event, extra={
        'extra_fields': {
            'event': event,
            **data
        }
    })

def log_mcp(event: str, **data):
    """Log MCP-specific events"""
    loggers['mcp'].info(event, extra={
        'extra_fields': {
            'event': event,
            **data
        }
    })

def log_error(error: str, **data):
    """Log errors with context"""
    loggers['error'].error(error, extra={
        'extra_fields': {
            'error': error,
            **data
        }
    })

def log_app(message: str, **data):
    """Log general application events"""
    loggers['app'].info(message, extra={
        'extra_fields': {
            **data
        }
    })

# Create separate FastAPI app for OAuth endpoints
app = FastAPI(title="ClodForest MCP + OAuth2 DCR Server", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://claude.ai", "https://www.claude.ai"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# In-memory storage (replace with persistent storage for production)
registered_clients: Dict[str, Dict[str, Any]] = {}
authorization_codes: Dict[str, Dict[str, Any]] = {}
access_tokens: Dict[str, Dict[str, Any]] = {}

# MCP Tools
@mcp.tool()
def hello(name: str = "World") -> str:
    """Test tool - greet the caller"""
    return f"Hello {name}! ClodForest MCP server with OAuth2 DCR is running."

@mcp.tool()
def list_contexts() -> str:
    """List all context files"""
    if not CONTEXT_DIR.exists():
        return f"Context directory not found: {CONTEXT_DIR}"

    files = []
    for item in CONTEXT_DIR.rglob("*"):
        if item.is_file():
            rel_path = item.relative_to(CONTEXT_DIR)
            files.append(str(rel_path))

    return "\n".join(sorted(files)) if files else "No context files found"

@mcp.tool()
def read_context(file_path: str) -> str:
    """Read a context file"""
    full_path = CONTEXT_DIR / file_path

    if not full_path.exists():
        return f"File not found: {file_path}"

    # Path traversal protection
    try:
        full_path.resolve().relative_to(CONTEXT_DIR.resolve())
    except ValueError:
        return "Invalid path: outside context directory"

    try:
        return full_path.read_text(encoding='utf-8')
    except (IOError, OSError, UnicodeDecodeError) as e:
        return f"Error reading file: {str(e)}"

@mcp.tool()
def search_contexts(query: str) -> str:
    """Search for text in context files"""
    if not CONTEXT_DIR.exists():
        return "Context directory not found"

    results = []
    for file_path in CONTEXT_DIR.rglob("*"):
        if not file_path.is_file():
            continue

        try:
            content = file_path.read_text(encoding='utf-8')
            if query.lower() in content.lower():
                rel_path = file_path.relative_to(CONTEXT_DIR)
                results.append(str(rel_path))
        except (IOError, OSError, UnicodeDecodeError):
            continue  # Skip unreadable files

    return "\n".join(sorted(results)) if results else f"No files contain: {query}"

@mcp.tool()
def write_context(file_path: str, content: str) -> str:
    """Write content to a context file (for local use)"""
    full_path = CONTEXT_DIR / file_path

    # Path traversal protection
    try:
        full_path.resolve().relative_to(CONTEXT_DIR.resolve())
    except ValueError:
        return "Invalid path: outside context directory"

    # Create parent directories if needed
    full_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        full_path.write_text(content, encoding='utf-8')
        return f"Successfully wrote {len(content)} characters to {file_path}"
    except (IOError, OSError) as e:
        return f"Failed to write file: {str(e)}"

# OAuth2 Helper Functions
def generate_client_credentials():
    """Generate secure client ID and secret"""
    client_id = f"clodforest_{secrets.token_urlsafe(16)}"
    client_secret = secrets.token_urlsafe(32)
    return client_id, client_secret

def generate_authorization_code():
    """Generate secure authorization code"""
    return secrets.token_urlsafe(32)

def generate_access_token():
    """Generate secure access token"""
    return secrets.token_urlsafe(32)

def verify_pkce_challenge(code_verifier: str, code_challenge: str, method: str = "S256") -> bool:
    """Verify PKCE code challenge"""
    if method == "S256":
        digest = hashlib.sha256(code_verifier.encode('utf-8')).digest()
        expected = base64.urlsafe_b64encode(digest).decode('utf-8').rstrip('=')
        return expected == code_challenge
    elif method == "plain":
        return code_verifier == code_challenge
    return False

def validate_token(token: str) -> Optional[Dict[str, Any]]:
    """Validate Bearer token and return token data"""
    if token not in access_tokens:
        return None

    token_data = access_tokens[token]
    if time.time() > token_data["expires_at"]:
        del access_tokens[token]
        return None

    return token_data

def cleanup_expired_tokens():
    """Clean up expired tokens from memory"""
    current_time = time.time()
    expired_tokens = [token for token, data in access_tokens.items()
                     if current_time > data["expires_at"]]
    for token in expired_tokens:
        del access_tokens[token]

    expired_codes = [code for code, data in authorization_codes.items()
                    if current_time > data["expires_at"]]
    for code in expired_codes:
        del authorization_codes[code]

# OAuth2 Discovery Endpoints
@app.get("/.well-known/oauth-authorization-server")
@app.get("/.well-known/oauth-authorization-server/")
@app.get("/.well-known/oauth-authorization-server/mcp")
async def oauth_discovery(request: Request):
    """RFC 8414 OAuth Authorization Server Metadata"""
    log_oauth("discovery_request", path=str(request.url.path))
    return JSONResponse(OAUTH_CONFIG)

@app.get("/.well-known/oauth-protected-resource/mcp")
async def oauth_resource_discovery():
    """OAuth Protected Resource Metadata for MCP"""
    return JSONResponse({
        "resource": "mcp",
        "authorization_servers": [OAUTH_CONFIG["issuer"]],
        "scopes_supported": OAUTH_CONFIG["scopes_supported"],
        "bearer_methods_supported": ["header"]
    })

# Dynamic Client Registration (RFC 7591)
@app.post("/register")
async def register_client(request_data: ClientRegistrationRequest, request: Request):
    """RFC 7591 Dynamic Client Registration"""
    
    log_oauth("client_registration_request", 
               client_name=request_data.client_name,
               client_uri=request_data.client_uri,
               scope=request_data.scope)
    
    # Clean up expired tokens periodically
    cleanup_expired_tokens()
    
    # Generate client credentials
    client_id, client_secret = generate_client_credentials()
    issued_at = int(time.time())
    expires_at = issued_at + (365 * 24 * 3600)  # 1 year expiration
    
    # Use provided redirect URIs or default to Claude.ai
    redirect_uris = request_data.redirect_uris or ["https://claude.ai/oauth/callback"]
    
    # Store client registration
    client_data = {
        "client_id": client_id,
        "client_secret": client_secret,
        "client_id_issued_at": issued_at,
        "client_secret_expires_at": expires_at,
        "client_name": request_data.client_name or "Claude.ai Client",
        "client_uri": request_data.client_uri,
        "grant_types": ["authorization_code"],
        "response_types": ["code"],
        "scope": request_data.scope or "mcp:read mcp:write",
        "token_endpoint_auth_method": "client_secret_basic",
        "redirect_uris": redirect_uris
    }
    
    registered_clients[client_id] = client_data
    
    log_oauth("client_registered", 
               client_id=client_id,
               client_name=client_data["client_name"],
               redirect_uris=redirect_uris,
               total_clients=len(registered_clients))
    
    response = ClientRegistrationResponse(**client_data)
    return JSONResponse(response.model_dump(), status_code=201)

# Authorization Endpoint
@app.get("/oauth/authorize")
async def authorize(
    request: Request,
    response_type: str,
    client_id: str,
    redirect_uri: Optional[str] = None,
    scope: Optional[str] = None,
    state: Optional[str] = None,
    code_challenge: Optional[str] = None,
    code_challenge_method: Optional[str] = None
):
    """OAuth 2.1 Authorization Endpoint"""
    
    log_oauth("authorization_request", 
               client_id=client_id,
               response_type=response_type,
               redirect_uri=redirect_uri,
               scope=scope,
               state=state,
               has_pkce=bool(code_challenge),
               registered_clients=list(registered_clients.keys()))
    
    # Validate client - with auto-registration fallback
    if client_id not in registered_clients:
        # Auto-register Claude.ai clients that are missing
        if client_id.startswith("clodforest_"):
            log_oauth("auto_registering_client", 
                       client_id=client_id,
                       reason="client_missing_from_memory")
            
            # Create a default registration for this client
            client_data = {
                "client_id": client_id,
                "client_secret": "auto_generated_secret",  # This won't work for token exchange, forcing re-registration
                "client_name": "Auto-registered Claude.ai Client",
                "redirect_uris": ["https://claude.ai/oauth/callback", "https://claude.ai/api/mcp/auth_callback"]
            }
            registered_clients[client_id] = client_data
            
            log_oauth("client_auto_registered", 
                       client_id=client_id,
                       note="temporary_registration_token_exchange_will_fail")
        else:
            log_oauth("authorization_failed", 
                       reason="client_not_found",
                       client_id=client_id,
                       available_clients=list(registered_clients.keys()))
            raise HTTPException(status_code=400, detail="Invalid client_id")
    
    client = registered_clients[client_id]
    
    # Validate response_type
    if response_type != "code":
        log_oauth("authorization_failed", 
                   reason="invalid_response_type",
                   response_type=response_type,
                   client_id=client_id)
        raise HTTPException(status_code=400, detail="Unsupported response_type")
    
    # Validate redirect_uri
    if redirect_uri and redirect_uri not in client.get("redirect_uris", []):
        log_oauth("authorization_failed", 
                   reason="invalid_redirect_uri",
                   redirect_uri=redirect_uri,
                   allowed_uris=client.get("redirect_uris"),
                   client_id=client_id)
        raise HTTPException(status_code=400, detail="Invalid redirect_uri")
    
    # Generate authorization code
    auth_code = generate_authorization_code()
    code_data = {
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "scope": scope or "mcp:read mcp:write",
        "expires_at": time.time() + 600,  # 10 minute expiration
        "code_challenge": code_challenge,
        "code_challenge_method": code_challenge_method
    }
    
    authorization_codes[auth_code] = code_data
    
    # Redirect back to client with authorization code
    callback_url = redirect_uri or client["redirect_uris"][0]
    params = f"code={auth_code}"
    if state:
        params += f"&state={state}"
    
    final_url = f"{callback_url}?{params}"
    
    log_oauth("authorization_code_generated", 
               client_id=client_id,
               auth_code=auth_code[:10] + "...",
               redirect_url=final_url,
               expires_in=600)
    
    return RedirectResponse(final_url)

# Token Endpoint
@app.post("/oauth/token")
async def token_endpoint(request: Request):
    """OAuth 2.1 Token Endpoint"""
    
    # Log the raw request for debugging
    body = await request.body()
    
    log_oauth("token_request", 
               content_type=request.headers.get("content-type"),
               body_length=len(body),
               headers=dict(request.headers))
    
    # Parse the request
    try:
        if request.headers.get("content-type") == "application/x-www-form-urlencoded":
            from urllib.parse import parse_qs
            form_data = parse_qs(body.decode('utf-8'))
            
            # Convert form data to TokenRequest format
            token_request = TokenRequest(
                grant_type=form_data.get('grant_type', [''])[0],
                code=form_data.get('code', [''])[0] or None,
                redirect_uri=form_data.get('redirect_uri', [''])[0] or None,
                client_id=form_data.get('client_id', [''])[0] or None,
                client_secret=form_data.get('client_secret', [''])[0] or None,
                code_verifier=form_data.get('code_verifier', [''])[0] or None
            )
        else:
            # JSON format
            import json
            json_data = json.loads(body)
            token_request = TokenRequest(**json_data)
    except Exception as e:
        log_oauth("token_request_parse_failed", 
                   error=str(e),
                   body=body.decode('utf-8', errors='ignore')[:200])
        raise HTTPException(status_code=400, detail=f"Invalid request format: {str(e)}")
    
    log_oauth("token_request_parsed", 
               grant_type=token_request.grant_type,
               client_id=token_request.client_id,
               has_code=bool(token_request.code),
               has_verifier=bool(token_request.code_verifier))
    
    if token_request.grant_type != "authorization_code":
        log_oauth("token_request_failed", 
                   reason="unsupported_grant_type",
                   grant_type=token_request.grant_type)
        raise HTTPException(status_code=400, detail="Unsupported grant_type")
    
    # Validate authorization code
    if not token_request.code or token_request.code not in authorization_codes:
        log_oauth("token_request_failed", 
                   reason="invalid_authorization_code",
                   provided_code=token_request.code[:10] + "..." if token_request.code else None,
                   available_codes=[code[:10] + "..." for code in authorization_codes.keys()])
        raise HTTPException(status_code=400, detail="Invalid authorization code")
    
    code_data = authorization_codes[token_request.code]
    
    # Check expiration
    if time.time() > code_data["expires_at"]:
        log_oauth("token_request_failed", 
                   reason="authorization_code_expired",
                   code=token_request.code[:10] + "...")
        del authorization_codes[token_request.code]
        raise HTTPException(status_code=400, detail="Authorization code expired")
    
    # Validate client
    if token_request.client_id != code_data["client_id"]:
        log_oauth("token_request_failed", 
                   reason="client_mismatch",
                   request_client=token_request.client_id,
                   code_client=code_data["client_id"])
        raise HTTPException(status_code=400, detail="Client mismatch")
    
    if token_request.client_id not in registered_clients:
        log_oauth("token_request_failed", 
                   reason="client_not_registered",
                   client_id=token_request.client_id)
        raise HTTPException(status_code=400, detail="Invalid client_id")
    
    client = registered_clients[token_request.client_id]
    if token_request.client_secret != client["client_secret"]:
        log_oauth("token_request_failed", 
                   reason="invalid_client_credentials",
                   client_id=token_request.client_id,
                   note="client_needs_to_reregister")
        raise HTTPException(status_code=401, detail="Invalid client credentials")
    
    # Validate PKCE if present
    if code_data.get("code_challenge") and token_request.code_verifier:
        if not verify_pkce_challenge(token_request.code_verifier, code_data["code_challenge"], code_data.get("code_challenge_method", "S256")):
            log_oauth("token_request_failed", 
                       reason="pkce_validation_failed",
                       client_id=token_request.client_id)
            raise HTTPException(status_code=400, detail="Invalid PKCE verification")
    
    # Generate access token
    access_token = generate_access_token()
    token_data = {
        "client_id": token_request.client_id,
        "scope": code_data["scope"],
        "expires_at": time.time() + 3600,  # 1 hour expiration
    }
    
    access_tokens[access_token] = token_data
    
    log_oauth("access_token_generated", 
               client_id=token_request.client_id,
               token=access_token[:10] + "...",
               scope=code_data["scope"],
               expires_in=3600)
    
    # Clean up authorization code (one-time use)
    del authorization_codes[token_request.code]
    
    return JSONResponse({
        "access_token": access_token,
        "token_type": "Bearer",
        "expires_in": 3600,
        "scope": code_data["scope"]
    })

# Health check endpoints
@app.get("/health")
@app.get("/health/")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "ClodForest MCP + OAuth2 DCR Server"}

@app.get("/api/health")
@app.get("/api/health/")
async def alb_health_check():
    """ALB health check endpoint"""
    return {"status": "ok", "service": "ClodForest MCP + OAuth2 DCR Server", "version": "1.0.0"}

# Debug endpoints (only in debug mode)
if DEBUG_MODE:
    @app.get("/debug/clients")
    async def debug_clients():
        """Debug: List registered clients"""
        return {"clients": list(registered_clients.keys())}

    @app.get("/debug/tokens")
    async def debug_tokens():
        """Debug: List active tokens"""
        return {"tokens": list(access_tokens.keys())}

    @app.get("/debug/config")
    async def debug_config():
        """Debug: Show current configuration"""
        return {"config": OAUTH_CONFIG, "debug_mode": DEBUG_MODE}

# Access logging middleware
@app.middleware("http")
async def access_logging_middleware(request: Request, call_next):
    """Log all HTTP requests in structured format"""
    start_time = time.time()
    
    # Process the request
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        
        log_access(request, response.status_code, 
                   process_time=process_time,
                   content_length=response.headers.get("content-length"))
        
        return response
    except Exception as e:
        process_time = time.time() - start_time
        
        log_access(request, 500, 
                   process_time=process_time,
                   error=str(e))
        
        raise

# MCP endpoint protection middleware
@app.middleware("http")
async def oauth_protection_middleware(request: Request, call_next):
    """Middleware to protect MCP endpoints with OAuth"""
    
    # Allow OAuth endpoints and health checks without authentication
    if request.url.path.startswith(("/.well-known", "/oauth", "/register", "/health", "/api/health", "/debug")):
        return await call_next(request)
    
    # For MCP endpoints, require OAuth authentication
    if request.url.path.startswith("/mcp"):
        try:
            auth_header = request.headers.get("authorization")
            
            if not auth_header or not auth_header.startswith("Bearer "):
                log_mcp("authentication_failed", 
                         reason="no_bearer_token",
                         path=request.url.path)
                return JSONResponse(
                    status_code=401,
                    content={"error": "Authorization header required"}
                )
            
            token = auth_header.split(" ")[1]
            
            token_data = validate_token(token)
            if not token_data:
                log_mcp("authentication_failed", 
                         reason="invalid_token",
                         token=token[:10] + "...",
                         available_tokens=[t[:10] + "..." for t in access_tokens.keys()])
                return JSONResponse(
                    status_code=401,
                    content={"error": "Invalid or expired token"}
                )
            
            log_mcp("authentication_success", 
                     client_id=token_data.get('client_id'),
                     token=token[:10] + "...",
                     path=request.url.path)
            
            # Token is valid, proceed with request
            return await call_next(request)
            
        except Exception as e:
            logger.error(f"Authentication failed: {e}")
            return JSONResponse(
                status_code=401,
                content={"error": f"Authentication failed: {str(e)}"}
            )
    
    # All other endpoints pass through normally
    return await call_next(request)

# MCP endpoint integration
@app.post("/mcp")
async def mcp_endpoint(request: Request):
    """MCP endpoint - handle MCP protocol requests"""
    try:
        # Get the raw request body
        body = await request.body()

        # For stdio mode, we need to integrate with FastMCP differently
        # This is a simplified implementation that would need proper MCP protocol handling

        # Parse JSON-RPC request
        import json
        try:
            mcp_request = json.loads(body)
        except json.JSONDecodeError:
            return JSONResponse(
                status_code=400,
                content={"error": "Invalid JSON-RPC request"}
            )

        # Basic MCP method routing
        method = mcp_request.get("method")
        params = mcp_request.get("params", {})
        request_id = mcp_request.get("id")

        if method == "tools/call":
            tool_name = params.get("name")
            tool_args = params.get("arguments", {})

            # Route to MCP tools
            if tool_name == "hello":
                result = hello(tool_args.get("name", "World"))
            elif tool_name == "list_contexts":
                result = list_contexts()
            elif tool_name == "read_context":
                result = read_context(tool_args.get("file_path", ""))
            elif tool_name == "search_contexts":
                result = search_contexts(tool_args.get("query", ""))
            elif tool_name == "write_context":
                result = write_context(tool_args.get("file_path", ""), tool_args.get("content", ""))
            else:
                return JSONResponse(
                    status_code=400,
                    content={"error": f"Unknown tool: {tool_name}"}
                )

            return JSONResponse({
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {"content": [{"type": "text", "text": result}]}
            })

        else:
            return JSONResponse(
                status_code=400,
                content={"error": f"Unknown method: {method}"}
            )

    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"Internal server error: {str(e)}"}
        )

if __name__ == "__main__":
    # Allow stdio for local testing
    if len(sys.argv) > 1 and sys.argv[1] == "--stdio":
        log_app("server_starting", mode="stdio", transport="Claude Desktop")
        mcp.run(transport="stdio")
    else:
        # Use HTTP with integrated OAuth
        host = "0.0.0.0"
        port = 8080
        
        log_app("server_starting", 
                 mode="http",
                 host=host,
                 port=port,
                 debug_mode=DEBUG_MODE,
                 oauth_issuer=OAUTH_CONFIG["issuer"])
        
        print(f"Starting ClodForest MCP + OAuth2 DCR server on http://{host}:{port}")
        print(f"OAuth Discovery: http://{host}:{port}/.well-known/oauth-authorization-server")
        print(f"Client Registration: http://{host}:{port}/register")
        print(f"MCP Endpoint: http://{host}:{port}/mcp")
        print(f"Health Check: http://{host}:{port}/api/health")
        print(f"Debug Mode: {DEBUG_MODE}")
        print(f"Logs Directory: {log_dir.absolute()}")
        print("\nStructured logs available in:")
        print(f"  - {log_dir}/access.log (HTTP requests)")
        print(f"  - {log_dir}/oauth.log (OAuth flow events)")
        print(f"  - {log_dir}/mcp.log (MCP authentication)")
        print(f"  - {log_dir}/error.log (Errors)")
        print(f"  - {log_dir}/app.log (Application events)")
        
        # Run the FastAPI app directly
        uvicorn.run(app, host=host, port=port)
