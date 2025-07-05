#!/usr/bin/env coffee
# FILENAME: create-initial-access-token.coffee
# Script to create an initial access token for oidc-provider registration

{ createProvider } = require './src/oauth/oidc-provider'

createInitialAccessToken = ->
  try
    # Create provider instance
    issuer = "http://localhost:8080"
    provider = createProvider issuer
    
    # Create initial access token with our policy
    InitialAccessToken = provider.InitialAccessToken
    token = new InitialAccessToken({ policies: ['mcp-grant-types'] })
    
    result = await token.save()
    console.log "Initial Access Token created:"
    console.log "Token: #{result}"
    console.log ""
    console.log "Use this token as Authorization: Bearer #{result}"
    console.log "when making client registration requests."
    
  catch error
    console.error "Error creating initial access token:", error.message
    console.error error.stack

if require.main is module
  createInitialAccessToken().catch (error) ->
    console.error 'Script error:', error
    process.exit 1
