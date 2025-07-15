#!/usr/bin/env python3
"""
Check FastMCP version and capabilities
"""

try:
    from fastmcp import FastMCP
    import fastmcp
    print(f"FastMCP 2.0 found: {fastmcp.__version__ if hasattr(fastmcp, '__version__') else 'version unknown'}")
    print("Import source: fastmcp")
    
    # Test mcp.run signature
    import inspect
    sig = inspect.signature(FastMCP.run)
    print(f"FastMCP.run signature: {sig}")
    
except ImportError:
    try:
        from mcp.server.fastmcp import FastMCP
        import mcp
        print(f"MCP SDK FastMCP found: {mcp.__version__ if hasattr(mcp, '__version__') else 'version unknown'}")
        print("Import source: mcp.server.fastmcp")
        
        # Test mcp.run signature  
        import inspect
        sig = inspect.signature(FastMCP.run)
        print(f"FastMCP.run signature: {sig}")
        
    except ImportError:
        print("No FastMCP installation found!")
        print("Please install: pip install fastmcp")
        exit(1)

# Test basic functionality
mcp = FastMCP("Test")

@mcp.tool()
def test_tool() -> str:
    """Test tool"""
    return "success"

print("✓ FastMCP server creation successful")
print("✓ Tool decoration successful")
