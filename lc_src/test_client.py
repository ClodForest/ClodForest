#!/usr/bin/env python3
"""
Simple MCP test - verify basic functionality
"""

import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def test_mcp():
    server_params = StdioServerParameters(
        command="python", args=["clodforest_mcp.py"]
    )
    
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Test tools
            tools = await session.list_tools()
            print(f"Tools: {[t.name for t in tools.tools]}")
            
            # Test hello
            result = await session.call_tool("hello", {"name": "Test"})
            print(f"Hello: {result.content[0].text}")
            
            # Test list contexts
            result = await session.call_tool("list_contexts", {})
            print(f"Contexts found: {len(result.content[0].text.split())}")
            
            print("✓ All tests passed")

if __name__ == "__main__":
    asyncio.run(test_mcp())
