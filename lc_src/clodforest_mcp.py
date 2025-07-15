#!/usr/bin/env python3
"""
ClodForest MCP Server - Minimal viable implementation
Exposes ClodForest state via Model Context Protocol
"""

from pathlib import Path
from mcp.server.fastmcp import FastMCP

# Initialize server and locate ClodForest state
mcp = FastMCP("ClodForest")
CONTEXT_DIR = Path(__file__).parent.parent / "state" / "contexts"

@mcp.tool()
def hello(name: str = "World") -> str:
    """Test tool - greet the caller"""
    return f"Hello {name}! ClodForest MCP server is running."

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

if __name__ == "__main__":
    mcp.run(transport="stdio")
