#!/usr/bin/env python3
"""
Test Streamable HTTP MCP server
"""

import asyncio
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

async def test_http_mcp():
    """Test the HTTP MCP server"""
    
    # Connect to local HTTP server
    async with streamablehttp_client("http://localhost:8080/mcp") as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Test tools
            tools = await session.list_tools()
            print(f"HTTP Tools: {[t.name for t in tools.tools]}")
            
            # Test hello
            result = await session.call_tool("hello", {"name": "HTTP Test"})
            print(f"Hello: {result.content[0].text}")
            
            # Test list contexts
            result = await session.call_tool("list_contexts", {})
            print(f"Contexts found: {len(result.content[0].text.split())}")
            
            print("✓ HTTP MCP tests passed")

if __name__ == "__main__":
    print("Testing ClodForest HTTP MCP Server...")
    print("Make sure to start the server first:")
    print("  python clodforest_mcp_http.py")
    print()
    
    try:
        asyncio.run(test_http_mcp())
    except Exception as e:
        print(f"✗ Test failed: {e}")
        print("Make sure the HTTP server is running on port 8080")
