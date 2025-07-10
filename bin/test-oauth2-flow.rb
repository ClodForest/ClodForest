#!/usr/bin/env ruby
# Modified OAuth2 tester that works with oidc-provider's redirect URI restrictions

require 'oauth2'
require 'awesome_print'

site          = ARGV[0] || 'http://localhost:8080'
client_id     = ARGV[1] || 'WAhRs_08XLTgPRkf0wZX3MyoL4eOb0go08mL2sXJREy'
client_secret = ARGV[2] || 'HZxGf-zs5-juwZYCvQpFR96K2NIUp3CuM-YJh0CE79tR9ytKNGY5EUkpk-63wz8CxlaJGJDijSN5VjovcVi8jQ'
scope         = ARGV[3] || 'mcp read write'
redirect_uri  = 'http://localhost:3000/callback'

puts "=== OAuth2 Authorization Code Flow Test ==="
puts "Site: #{site}"
puts "Client ID: #{client_id}"
puts "Scope: #{scope}"
puts "Redirect URI: #{redirect_uri}"
puts ""

client = OAuth2::Client.new(client_id, client_secret, site: site)

url_params = { redirect_uri: redirect_uri }
url_params.merge!(scope: scope) if scope

authorization_url = client.auth_code.authorize_url(url_params)

puts "Authorization URL:"
puts authorization_url
puts ""
puts "Steps:"
puts "1. Open the URL above in your browser"
puts "2. Authorize the application"
puts "3. Copy the 'code' parameter from the callback URL"
puts "4. Paste it below"
puts ""

print "Enter the authorization code: "
authorization_code = $stdin.gets.chomp

puts "Authorization Code: #{authorization_code}"

begin
  token = client.auth_code.get_token(authorization_code, redirect_uri: redirect_uri)
  puts ""
  puts "=== Token Response ==="
  ap token.to_hash
  
  puts ""
  puts "Access Token: #{token.token}"
  puts ""
  
  # Test MCP endpoint
  puts "=== Testing MCP Endpoint ==="
  mcp_response = token.post('/api/mcp', 
    headers: { 'Content-Type' => 'application/json' },
    body: {
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2025-06-18',
        capabilities: {},
        clientInfo: {
          name: 'Ruby OAuth2 Test Client',
          version: '1.0.0'
        }
      }
    }.to_json
  )
  
  puts "MCP Response:"
  ap JSON.parse(mcp_response.body)
  
rescue => error
  puts ""
  puts "Error: #{error.message}"
  ap error
end