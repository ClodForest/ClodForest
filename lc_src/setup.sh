#!/bin/bash
# ClodForest MCP Server - Minimal setup

set -e
cd "$(dirname "$0")"

echo "Setting up ClodForest MCP Server..."

python3.13 -m venv venv
source venv/bin/activate

# Install dependencies
pip install mcp

# Test server
echo "Testing server..."
echo '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}' | python clodforest_mcp.py

echo "✓ Setup complete"
echo "Run: python clodforest_mcp.py"
