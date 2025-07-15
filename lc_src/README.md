# ClodForest MCP Server

Minimal MCP server exposing ClodForest state to AI clients via both stdio and HTTP transports.

## Setup

```bash
pip install mcp
```

## Tools

- `hello(name)` - Test connectivity
- `list_contexts()` - Show all context files
- `read_context(file_path)` - Read specific file
- `search_contexts(query)` - Find files containing text
- `write_context(file_path, content)` - Write new context file

## Local Usage (stdio)

```bash
python clodforest_mcp.py  # stdio transport
python test_client.py     # test stdio
```

### Claude Desktop Config (stdio)

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "clodforest": {
      "command": "python",
      "args": ["/Users/robert/git/github/ClodForest/ClodForest/lc_src/clodforest_mcp.py"],
      "transport": "stdio"
    }
  }
}
```

## Remote Usage (HTTP)

```bash
python clodforest_mcp_http.py  # HTTP server on port 8080
python test_http_client.py     # test HTTP
```

### Claude.ai Remote Integration

1. Start HTTP server: `python clodforest_mcp_http.py`
2. In Claude.ai, go to Settings > Integrations > Add more
3. Enter URL: `http://localhost:8080/mcp`
4. For public access, deploy with proper OAuth (see OAuth section)

## OAuth Integration (Future)

For Claude.ai remote access with authentication:
- Requires Dynamic Client Registration (DCR) support
- Consider using `mcp-front` proxy for OAuth 2.1
- Or deploy on Cloudflare with built-in OAuth

## Next Steps

1. Test stdio with Claude Desktop ✓
2. Test HTTP with Claude.ai (local network)
3. Add OAuth for public remote access
4. Use for LangGraph context migration
