#!/usr/bin/env coffee
# FILENAME: test/rfc8414-compliance-test.coffee

http  = require 'node:http'
https = require 'node:https'
{ URL } = require 'node:url'

CONFIG =
  baseUrl: 'http://localhost:8080'

RFC8414_REQUIRED_FIELDS = [
  'issuer'
  'response_types_supported'
]

RFC8414_OPTIONAL_FIELDS = [
  'authorization_endpoint'
  'token_endpoint'
  'jwks_uri'
  'registration_endpoint'
  'scopes_supported'
  'response_modes_supported'
  'grant_types_supported'
  'token_endpoint_auth_methods_supported'
  'token_endpoint_auth_signing_alg_values_supported'
  'service_documentation'
  'ui_locales_supported'
  'op_policy_uri'
  'op_tos_uri'
  'revocation_endpoint'
  'revocation_endpoint_auth_methods_supported'
  'revocation_endpoint_auth_signing_alg_values_supported'
  'introspection_endpoint'
  'introspection_endpoint_auth_methods_supported'
  'introspection_endpoint_auth_signing_alg_values_supported'
  'code_challenge_methods_supported'
]

runRFC8414ComplianceTest = ->
  console.log '📋 RFC 8414 OAuth2 Authorization Server Metadata Compliance Test'
  console.log "Server: #{CONFIG.baseUrl}"
  
  # Test RFC 8414 Section 3: Obtaining Authorization Server Metadata
  metadata = await testStep 'RFC 8414 Discovery Endpoint', getDiscoveryMetadata()
  
  return unless metadata
  
  # Test RFC 8414 Section 2: Authorization Server Metadata
  await testStep 'RFC 8414 Required Fields',     validateRequiredFields(metadata)
  await testStep 'RFC 8414 Optional Fields',     validateOptionalFields(metadata)
  await testStep 'RFC 8414 Field Types',         validateFieldTypes(metadata)
  await testStep 'RFC 8414 Issuer Validation',   validateIssuer(metadata)
  await testStep 'RFC 8414 Endpoint URLs',       validateEndpointUrls(metadata)
  
  console.log '\n📋 RFC 8414 compliance test complete'

testStep = (name, testFunction) ->
  console.log "\n=== #{name} ==="
  
  try
    result = await testFunction
    if result.success
      console.log "✅ #{name}: #{result.message}"
      return result.data
    else
      console.log "❌ #{name}: #{result.message}"
      return null
  catch error
    console.log "❌ #{name} error:", error.message
    return null

getDiscoveryMetadata = ->
  try
    response = await makeRequest
      url    : "#{CONFIG.baseUrl}/.well-known/oauth-authorization-server"
      method : 'GET'
    
    if response.status is 200
      success : true
      message : 'Discovery endpoint accessible'
      data    : response.body
    else
      success : false
      message : "Discovery endpoint returned status #{response.status}"
  catch error
    success : false
    message : "Discovery endpoint error: #{error.message}"

validateRequiredFields = (metadata) ->
  missingFields = RFC8414_REQUIRED_FIELDS.filter (field) -> not metadata[field]?
  
  if missingFields.length is 0
    success : true
    message : 'All required fields present'
  else
    success : false
    message : "Missing required fields: #{missingFields.join(', ')}"

validateOptionalFields = (metadata) ->
  presentFields = RFC8414_OPTIONAL_FIELDS.filter (field) -> metadata[field]?
  
  success : true
  message : "#{presentFields.length}/#{RFC8414_OPTIONAL_FIELDS.length} optional fields present: #{presentFields.join(', ')}"

validateFieldTypes = (metadata) ->
  errors = []
  
  # issuer must be string with https scheme (RFC 8414 Section 2)
  if typeof metadata.issuer isnt 'string'
    errors.push 'issuer must be string'
  else unless metadata.issuer.startsWith('http')  # Allow http for local testing
    errors.push 'issuer must be URL'
  
  # Arrays must be arrays
  arrayFields = [
    'response_types_supported'
    'response_modes_supported'
    'grant_types_supported'
    'scopes_supported'
    'token_endpoint_auth_methods_supported'
    'token_endpoint_auth_signing_alg_values_supported'
    'ui_locales_supported'
    'code_challenge_methods_supported'
  ]
  
  for field in arrayFields when metadata[field]?
    unless Array.isArray metadata[field]
      errors.push "#{field} must be array"
  
  # URLs must be strings
  urlFields = [
    'authorization_endpoint'
    'token_endpoint'
    'jwks_uri'
    'registration_endpoint'
    'service_documentation'
    'op_policy_uri'
    'op_tos_uri'
    'revocation_endpoint'
    'introspection_endpoint'
  ]
  
  for field in urlFields when metadata[field]?
    unless typeof metadata[field] is 'string'
      errors.push "#{field} must be string URL"
  
  if errors.length is 0
    success : true
    message : 'All field types valid'
  else
    success : false
    message : "Type validation errors: #{errors.join(', ')}"

validateIssuer = (metadata) ->
  # RFC 8414 Section 3.3: issuer value must match the URL used to retrieve metadata
  expectedIssuer = CONFIG.baseUrl
  
  if metadata.issuer is expectedIssuer
    success : true
    message : 'Issuer identifier matches discovery URL'
  else
    success : false
    message : "Issuer mismatch: expected '#{expectedIssuer}', got '#{metadata.issuer}'"

validateEndpointUrls = (metadata) ->
  errors = []
  baseUrl = CONFIG.baseUrl
  
  # Validate that endpoints use same base URL as issuer
  endpointFields = [
    'authorization_endpoint'
    'token_endpoint'
    'registration_endpoint'
    'introspection_endpoint'
    'revocation_endpoint'
  ]
  
  for field in endpointFields when metadata[field]?
    unless metadata[field].startsWith(baseUrl)
      errors.push "#{field} should use same base URL as issuer"
  
  # Validate specific endpoint paths match our implementation
  expectedEndpoints =
    token_endpoint         : "#{baseUrl}/oauth/token"
    registration_endpoint  : "#{baseUrl}/oauth/register"
    introspection_endpoint : "#{baseUrl}/oauth/introspect"
  
  for field, expectedUrl of expectedEndpoints when metadata[field]?
    unless metadata[field] is expectedUrl
      errors.push "#{field} path mismatch: expected '#{expectedUrl}', got '#{metadata[field]}'"
  
  if errors.length is 0
    success : true
    message : 'All endpoint URLs valid'
  else
    success : false
    message : "Endpoint validation errors: #{errors.join(', ')}"

makeRequest = (options) ->
  new Promise (resolve, reject) ->
    url = new URL options.url
    protocol = if url.protocol is 'https:' then https else http
    
    reqOptions =
      hostname : url.hostname
      port     : url.port or (if url.protocol is 'https:' then 443 else 80)
      path     : url.pathname + url.search
      method   : options.method or 'GET'
      headers  : options.headers or {}
    
    if options.data
      reqOptions.headers['Content-Type'] or= 'application/json'
      reqOptions.headers['Content-Length'] = Buffer.byteLength options.data
    
    req = protocol.request reqOptions, (res) ->
      body = ''
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', ->
        try
          result =
            status  : res.statusCode
            headers : res.headers
            body    : if body then JSON.parse(body) else null
          resolve result
        catch error
          resolve
            status     : res.statusCode
            headers    : res.headers
            body       : body
            parseError : error.message
    
    req.on 'error', reject
    req.write options.data if options.data
    req.end()

if require.main is module
  runRFC8414ComplianceTest().catch (error) ->
    console.error 'RFC 8414 compliance test error:', error
    process.exit 1
else
  module.exports = { runRFC8414ComplianceTest }
