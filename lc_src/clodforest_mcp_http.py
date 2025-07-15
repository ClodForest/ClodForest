#!/usr/bin/env python3
"""
ClodForest MCP Server - Streamable HTTP version
Exposes ClodForest state via Model Context Protocol for Claude.ai remote access
"""

from pathlib import Path

# Try both import paths - fastmcp 2.0 vs mcp.server.fastmcp
try:
    from fastmcp import FastMCP
except ImportError:
    try:
        from mcp.server.fastmcp import FastMCP
    except ImportError:
        print("Error: Neither 'fastmcp' nor 'mcp.server.fastmcp' found.")
        print("Please install: pip install fastmcp")
        exit(1)

# Initialize server and locate ClodForest state
mcp = FastMCP("ClodForest")
CONTEXT_DIR = Path(__file__).parent.parent / "state" / "contexts"

@mcp.tool()
def hello(name: str = "World") -> str:
    """Test tool - greet the caller"""
    return f"Hello {name}! ClodForest MCP server is running via Streamable HTTP."

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
    
    if not full_path.is_relative_to(CONTEXT_DIR):
        return "Invalid path"
    
    return full_path.read_text(encoding='utf-8')

@mcp.tool()
def search_contexts(query: str) -> str:
    """Search for text in context files"""
    if not CONTEXT_DIR.exists():
        return "Context directory not found"
    
    results = []
    for file_path in CONTEXT_DIR.rglob("*.md"):
        try:
            content = file_path.read_text(encoding='utf-8')
            if query.lower() in content.lower():
                rel_path = file_path.relative_to(CONTEXT_DIR)
                results.append(str(rel_path))
        except:
            continue  # Skip unreadable files
    
    return "\n".join(sorted(results)) if results else f"No files contain: {query}"

@mcp.tool()
def write_context(file_path: str, content: str) -> str:
    """Write content to a context file (for local use)"""
    full_path = CONTEXT_DIR / file_path
    
    if not full_path.is_relative_to(CONTEXT_DIR):
        return "Invalid path"
    
    # Create parent directories if needed
    full_path.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        full_path.write_text(content, encoding='utf-8')
        return f"Successfully wrote {len(content)} characters to {file_path}"
    except Exception as e:
        return f"Failed to write file: {str(e)}"

if __name__ == "__main__":
    import sys
    
    # Allow stdio for local testing
    if len(sys.argv) > 1 and sys.argv[1] == "--stdio":
        mcp.run(transport="stdio")
    else:
        # Use streamable-http for remote access
        host = "127.0.0.1"
        port = 8080
        print(f"Starting ClodForest MCP server on http://{host}:{port}/mcp")
        print(f"Connect from Claude.ai using: http://{host}:{port}/mcp")
        mcp.run(transport="http", host=host, port=port, path="/mcp")
