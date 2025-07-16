#!/usr/bin/env python3
"""
OAuth2 Dynamic Client Registration Server for ClodForest MCP
Implements RFC 7591 DCR + OAuth 2.1 for Claude.ai compatibility
"""

import secrets
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, Optional
import json
import hashlib
import base64

from fastapi import FastAPI, HTTPException, Request, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse, RedirectResponse
from pydantic import BaseModel, Field
import httpx

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

class TokenRequest(BaseModel):
    """OAuth 2.1 Token Request"""
    grant_type: str
    code: Optional[str] = None
    redirect_uri: Optional[str] = None
    client_id: Optional[str] = None
    client_secret: Optional[str] = None
    code_verifier: Optional[str] = None

# Initialize FastAPI app
app = FastAPI(title="ClodForest OAuth2 DCR Server", version="1.0.0")
security = HTTPBearer(auto_error=False)

# Configuration
OAUTH_CONFIG = {
    "issuer": "https://clodforest.thatsnice.org",
    "authorization_endpoint": "https://clodforest.thatsnice.org/oauth/authorize",
    "token_endpoint": "https://clodforest.thatsnice.org/oauth/token", 
    "registration_endpoint": "https://clodforest.thatsnice.org/register",
    "scopes_supported": ["mcp:read", "mcp:write"],
    "response_types_supported": ["code"],
    "grant_types_supported": ["authorization_code"],
    "token_endpoint_auth_methods_supported": ["client_secret_basic", "client_secret_post"],
    "code_challenge_methods_supported": ["S256"],
}

# In-memory storage (replace with persistent storage for production)
registered_clients: Dict[str, Dict[str, Any]] = {}
authorization_codes: Dict[str, Dict[str, Any]] = {}
access_tokens: Dict[str, Dict[str, Any]] = {}

# MCP server configuration
MCP_SERVER_URL = "http://127.0.0.1:8080/mcp"

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

# OAuth2 Discovery Endpoint
@app.get("/.well-known/oauth-authorization-server")
async def oauth_discovery():
    """RFC 8414 OAuth Authorization Server Metadata"""
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
async def register_client(request: ClientRegistrationRequest):
    """RFC 7591 Dynamic Client Registration"""
    
    # Generate client credentials
    client_id, client_secret = generate_client_credentials()
    issued_at = int(time.time())
    expires_at = issued_at + (365 * 24 * 3600)  # 1 year expiration
    
    # Store client registration
    client_data = {
        "client_id": client_id,
        "client_secret": client_secret,
        "client_id_issued_at": issued_at,
        "client_secret_expires_at": expires_at,
        "client_name": request.client_name or "Claude.ai Client",
        "client_uri": request.client_uri,
        "grant_types": ["authorization_code"],
        "response_types": ["code"],
        "scope": request.scope or "mcp:read mcp:write",
        "token_endpoint_auth_method": "client_secret_basic",
        "redirect_uris": ["https://claude.ai/oauth/callback"]  # Claude.ai callback
    }
    
    registered_clients[client_id] = client_data
    
    response = ClientRegistrationResponse(**client_data)
    return JSONResponse(response.dict(), status_code=201)

# Authorization Endpoint
@app.get("/oauth/authorize")
async def authorize(
    response_type: str,
    client_id: str,
    redirect_uri: Optional[str] = None,
    scope: Optional[str] = None,
    state: Optional[str] = None,
    code_challenge: Optional[str] = None,
    code_challenge_method: Optional[str] = None
):
    """OAuth 2.1 Authorization Endpoint"""
    
    # Validate client
    if client_id not in registered_clients:
        raise HTTPException(status_code=400, detail="Invalid client_id")
    
    client = registered_clients[client_id]
    
    # Validate response_type
    if response_type != "code":
        raise HTTPException(status_code=400, detail="Unsupported response_type")
    
    # Validate redirect_uri
    if redirect_uri and redirect_uri not in client.get("redirect_uris", []):
        raise HTTPException(status_code=400, detail="Invalid redirect_uri")
    
    # For ClodForest, we'll auto-approve Claude.ai requests
    # In production, you might want user consent here
    
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
    callback_url = redirect_uri or "https://claude.ai/oauth/callback"
    params = f"code={auth_code}"
    if state:
        params += f"&state={state}"
    
    return RedirectResponse(f"{callback_url}?{params}")

# Token Endpoint
@app.post("/oauth/token")
async def token_endpoint(request: TokenRequest):
    """OAuth 2.1 Token Endpoint"""
    
    if request.grant_type != "authorization_code":
        raise HTTPException(status_code=400, detail="Unsupported grant_type")
    
    # Validate authorization code
    if not request.code or request.code not in authorization_codes:
        raise HTTPException(status_code=400, detail="Invalid authorization code")
    
    code_data = authorization_codes[request.code]
    
    # Check expiration
    if time.time() > code_data["expires_at"]:
        del authorization_codes[request.code]
        raise HTTPException(status_code=400, detail="Authorization code expired")
    
    # Validate client
    if request.client_id != code_data["client_id"]:
        raise HTTPException(status_code=400, detail="Client mismatch")
    
    client = registered_clients[request.client_id]
    if request.client_secret != client["client_secret"]:
        raise HTTPException(status_code=401, detail="Invalid client credentials")
    
    # Validate PKCE if present
    if code_data.get("code_challenge") and request.code_verifier:
        if not verify_pkce_challenge(request.code_verifier, code_data["code_challenge"], code_data.get("code_challenge_method", "S256")):
            raise HTTPException(status_code=400, detail="Invalid PKCE verification")
    
    # Generate access token
    access_token = generate_access_token()
    token_data = {
        "client_id": request.client_id,
        "scope": code_data["scope"],
        "expires_at": time.time() + 3600,  # 1 hour expiration
    }
    
    access_tokens[access_token] = token_data
    
    # Clean up authorization code (one-time use)
    del authorization_codes[request.code]
    
    return JSONResponse({
        "access_token": access_token,
        "token_type": "Bearer",
        "expires_in": 3600,
        "scope": code_data["scope"]
    })

# Token validation helper
async def validate_token(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Dict[str, Any]:
    """Validate Bearer token"""
    if not credentials:
        raise HTTPException(status_code=401, detail="Authorization header required")
    
    token = credentials.credentials
    if token not in access_tokens:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    token_data = access_tokens[token]
    if time.time() > token_data["expires_at"]:
        del access_tokens[token]
        raise HTTPException(status_code=401, detail="Token expired")
    
    return token_data

# MCP Proxy Endpoints (OAuth Protected)
@app.api_route("/mcp/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def mcp_proxy(request: Request, path: str, token_data: Dict[str, Any] = Depends(validate_token)):
    """Proxy authenticated requests to MCP server"""
    
    # Forward request to MCP server
    async with httpx.AsyncClient() as client:
        url = f"{MCP_SERVER_URL}/{path}" if path else MCP_SERVER_URL
        
        # Forward headers (except Authorization)
        headers = dict(request.headers)
        headers.pop("authorization", None)
        
        # Forward request
        response = await client.request(
            method=request.method,
            url=url,
            headers=headers,
            content=await request.body(),
            params=request.query_params
        )
        
        return JSONResponse(
            content=response.json() if response.headers.get("content-type", "").startswith("application/json") else response.text,
            status_code=response.status_code,
            headers=dict(response.headers)
        )

# Health check endpoints
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "ClodForest OAuth2 DCR Server"}

@app.get("/api/health")
async def alb_health_check():
    """ALB health check endpoint"""
    return {"status": "ok", "service": "ClodForest OAuth2 DCR Server", "version": "1.0.0"}

# Debug endpoints (remove in production)
@app.get("/debug/clients")
async def debug_clients():
    """Debug: List registered clients"""
    return {"clients": list(registered_clients.keys())}

@app.get("/debug/tokens")
async def debug_tokens():
    """Debug: List active tokens"""
    return {"tokens": list(access_tokens.keys())}

if __name__ == "__main__":
    import uvicorn
    print("Starting ClodForest OAuth2 DCR Server...")
    print("Discovery endpoint: http://localhost:8000/.well-known/oauth-authorization-server")
    print("Registration endpoint: http://localhost:8000/register")
    print("MCP proxy: http://localhost:8000/mcp")
    uvicorn.run(app, host="0.0.0.0", port=8000)
