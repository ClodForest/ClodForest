#!/usr/bin/env python3
"""
Test FastMCP integration with ClodForest
"""

import asyncio
import httpx
import json

async def test_mcp_tools():
    """Test that our MCP tools are properly exposed"""
    
    base_url = "http://localhost:8080"
    
    # First, let's see what happens when we try to access MCP without auth
    print("Testing MCP endpoint without authentication...")
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(f"{base_url}/mcp", json={
                "jsonrpc": "2.0",
                "method": "tools/list",
                "id": 1
            })
            print(f"Response status: {response.status_code}")
            print(f"Response: {response.text}")
        except Exception as e:
            print(f"Error: {e}")
    
    print("\n" + "="*50 + "\n")
    
    # Test OAuth flow (simplified - we'll just check discovery)
    print("Testing OAuth discovery...")
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{base_url}/.well-known/oauth-authorization-server")
            print(f"Discovery status: {response.status_code}")
            if response.status_code == 200:
                discovery = response.json()
                print(f"Authorization endpoint: {discovery.get('authorization_endpoint')}")
                print(f"Token endpoint: {discovery.get('token_endpoint')}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_mcp_tools())
