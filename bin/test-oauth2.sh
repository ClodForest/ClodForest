#!/bin/bash
# Simple OAuth2 and MCP test script

BASE_URL="http://localhost:8080"

echo "=== Testing ClodForest OAuth2 and MCP ==="
echo ""

# Step 1: Register a client
echo "1. Registering OAuth2 client..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/oauth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Test OAuth2 Client",
    "grant_types": ["client_credentials", "authorization_code"],
    "scope": "mcp read write"
  }')

if [ $? -ne 0 ]; then
  echo "Error: Failed to register client"
  exit 1
fi

CLIENT_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"client_id":"[^"]*"' | cut -d'"' -f4)
CLIENT_SECRET=$(echo "$REGISTER_RESPONSE" | grep -o '"client_secret":"[^"]*"' | cut -d'"' -f4)

echo "Client registered successfully!"
echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
echo ""

# Step 2: Get an access token using client_credentials grant
echo "2. Requesting access token..."
AUTH=$(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)
TOKEN_RESPONSE=$(curl -s -X POST "$BASE_URL/oauth/token" \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&scope=mcp read write")

if [ $? -ne 0 ]; then
  echo "Error: Failed to get access token"
  exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: No access token in response"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "Access token obtained successfully!"
echo "Token: ${ACCESS_TOKEN:0:20}..."
echo ""

# Step 3: Test MCP endpoint
echo "3. Testing MCP initialize..."
MCP_RESPONSE=$(curl -s -X POST "$BASE_URL/api/mcp" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-06-18",
      "capabilities": {},
      "clientInfo": {
        "name": "Test Client",
        "version": "1.0.0"
      }
    }
  }')

echo "MCP Response: $MCP_RESPONSE"
echo ""

# Step 4: List available tools
echo "4. Listing MCP tools..."
TOOLS_RESPONSE=$(curl -s -X POST "$BASE_URL/api/mcp" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list",
    "params": {}
  }')

echo "Available tools: $TOOLS_RESPONSE"
echo ""

# Step 5: Test authorization_code flow URL
echo "5. Authorization code flow URL:"
echo "$BASE_URL/oauth/authorize?client_id=$CLIENT_ID&response_type=code&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=mcp"
echo ""
echo "You can use the oauth2_tester.rb with:"
echo "ruby bin/oauth2_tester.rb $BASE_URL $CLIENT_ID $CLIENT_SECRET mcp"