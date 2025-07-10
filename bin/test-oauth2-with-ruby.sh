#!/bin/bash
# Test OAuth2 with the Ruby oauth2_tester.rb script

# Use the credentials we just obtained
CLIENT_ID="PIPMpFjqAlzi0iQs_plV3DSrxwyir3JhI1hCL0_z1Kl"
CLIENT_SECRET="LMRkAkCp90B9uJnTfi_AOlYMaTk9l7mE1lwufmNjwptN98sHuzqkx0cdUDj93KxU7-o5WpGd05Orwips6BMR3A"
SITE="http://localhost:8080"
SCOPE="mcp read write"

echo "Testing OAuth2 with Ruby oauth2_tester.rb"
echo ""
echo "Site: $SITE"
echo "Client ID: $CLIENT_ID"
echo "Scope: $SCOPE"
echo ""
echo "This will open a browser for authorization. After authorizing, copy the code and paste it here."
echo ""

# Run the Ruby OAuth2 tester
/opt/homebrew/Cellar/ruby/3.4.4/bin/ruby bin/oauth2_tester.rb "$SITE" "$CLIENT_ID" "$CLIENT_SECRET" "$SCOPE"