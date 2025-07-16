#!/usr/bin/env python3
"""
Test script for ClodForest Integrated MCP + OAuth2 DCR
Tests against single-port service on localhost:8080
"""

import httpx
import json
import urllib.parse

async def test_integrated_oauth_flow():
    """Test the complete OAuth2 DCR flow on single port"""
    base_url = "http://localhost:8080"
    
    async with httpx.AsyncClient() as client:
        print("🔍 Testing Integrated MCP + OAuth2 DCR Flow...")
        print("="*50)
        
        # 1. Test discovery endpoint
        print("1. Testing OAuth discovery...")
        response = await client.get(f"{base_url}/.well-known/oauth-authorization-server")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            discovery = response.json()
            print(f"   Issuer: {discovery.get('issuer')}")
            print(f"   Registration: {discovery.get('registration_endpoint')}")
        print()
        
        # 2. Test client registration
        print("2. Testing client registration...")
        registration_data = {
            "client_name": "Test Claude Client",
            "client_uri": "https://claude.ai",
            "scope": "mcp:read mcp:write"
        }
        
        response = await client.post(
            f"{base_url}/register",
            json=registration_data
        )
        print(f"   Status: {response.status_code}")
        
        if response.status_code != 201:
            print(f"   Error: {response.text}")
            return
            
        client_info = response.json()
        client_id = client_info["client_id"]
        client_secret = client_info["client_secret"]
        print(f"   Client ID: {client_id}")
        print(f"   Client Secret: {client_secret[:10]}...")
        print()
        
        # 3. Test authorization endpoint
        print("3. Testing authorization...")
        auth_params = {
            "response_type": "code",
            "client_id": client_id,
            "redirect_uri": "https://claude.ai/oauth/callback",
            "scope": "mcp:read mcp:write",
            "state": "test_state_123"
        }
        
        # Don't follow redirects so we can see the auth code
        response = await client.get(
            f"{base_url}/oauth/authorize",
            params=auth_params,
            follow_redirects=False
        )
        print(f"   Status: {response.status_code}")
        
        if response.status_code != 302:
            print(f"   Error: {response.text}")
            return
            
        # Extract auth code from redirect
        location = response.headers.get("location", "")
        parsed = urllib.parse.urlparse(location)
        query_params = urllib.parse.parse_qs(parsed.query)
        auth_code = query_params.get("code", [None])[0]
        
        if not auth_code:
            print(f"   Error: No auth code in redirect: {location}")
            return
            
        print(f"   Auth Code: {auth_code[:10]}...")
        print()
        
        # 4. Test token exchange
        print("4. Testing token exchange...")
        token_data = {
            "grant_type": "authorization_code",
            "code": auth_code,
            "redirect_uri": "https://claude.ai/oauth/callback",
            "client_id": client_id,
            "client_secret": client_secret
        }
        
        response = await client.post(f"{base_url}/oauth/token", json=token_data)
        print(f"   Status: {response.status_code}")
        
        if response.status_code != 200:
            print(f"   Error: {response.text}")
            return
            
        token_info = response.json()
        access_token = token_info["access_token"]
        print(f"   Access Token: {access_token[:10]}...")
        print(f"   Expires In: {token_info.get('expires_in')} seconds")
        print()
        
        # 5. Test MCP access with token
        print("5. Testing MCP access...")
        headers = {"Authorization": f"Bearer {access_token}"}
        
        # Test the hello tool via MCP
        response = await client.post(
            f"{base_url}/mcp",
            headers=headers,
            json={
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "hello",
                    "arguments": {"name": "Integrated OAuth Test"}
                }
            }
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   Response: {result}")
        else:
            print(f"   Error: {response.text}")
        print()
        
        # 6. Test health endpoints
        print("6. Testing health endpoints...")
        
        # Test standard health endpoint
        response = await client.get(f"{base_url}/health")
        print(f"   /health Status: {response.status_code}")
        if response.status_code == 200:
            health_data = response.json()
            print(f"   Service: {health_data.get('service')}")
        
        # Test ALB health endpoint
        response = await client.get(f"{base_url}/api/health")
        print(f"   /api/health Status: {response.status_code}")
        if response.status_code == 200:
            health_data = response.json()
            print(f"   Service: {health_data.get('service')}")
            print(f"   Version: {health_data.get('version')}")
        print()
        
        # 7. Test unauthorized MCP access
        print("7. Testing unauthorized MCP access...")
        response = await client.post(
            f"{base_url}/mcp",
            json={
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "hello",
                    "arguments": {"name": "Unauthorized Test"}
                }
            }
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 401:
            print("   ✅ Correctly rejected unauthorized request")
        else:
            print(f"   ⚠️  Unexpected response: {response.text}")
        print()
        
        print("✅ Integrated MCP + OAuth2 DCR flow test complete!")

if __name__ == "__main__":
    import asyncio
    asyncio.run(test_integrated_oauth_flow())
