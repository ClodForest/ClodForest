#!/bin/bash
# register_client.sh

curl -X POST http://localhost:8080/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "redirect_uris": ["http://localhost:8080/"],
    "client_name": "OAuth2 Tester Gist",
    "grant_types": ["authorization_code"],
    "response_types": ["code"],
    "token_endpoint_auth_method": "none"
  }' | jq -r '.client_id'
