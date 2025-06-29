# FILENAME: { ClodForest/src/coordinator/lib/mcp/jsonrpc.coffee }
# JSON-RPC 2.0 Protocol Implementation for MCP

methods = require './methods'

# JSON-RPC Error Codes
ERROR_CODES =
  PARSE_ERROR:      -32700
  INVALID_REQUEST:  -32600
  METHOD_NOT_FOUND: -32601
  INVALID_PARAMS:   -32602
  INTERNAL_ERROR:   -32603

# Create JSON-RPC error response
createErrorResponse = (id, code, message, data = null) ->
  response =
    jsonrpc: '2.0'
    error:
      code:    code
      message: message
    id: id
  
  if data?
    response.error.data = data
  
  response

# Create JSON-RPC success response
createSuccessResponse = (id, result) ->
  jsonrpc: '2.0'
  result:  result
  id:      id

# Validate JSON-RPC request structure
validateRequest = (request) ->
  # Check required fields
  unless request.jsonrpc is '2.0'
    return createErrorResponse(
      request.id or null,
      ERROR_CODES.INVALID_REQUEST,
      'Invalid JSON-RPC version'
    )
  
  unless request.method and typeof request.method is 'string'
    return createErrorResponse(
      request.id or null,
      ERROR_CODES.INVALID_REQUEST,
      'Missing or invalid method'
    )
  
  # ID can be string, number, or null for notifications
  if request.id? and typeof request.id not in ['string', 'number']
    return createErrorResponse(
      null,
      ERROR_CODES.INVALID_REQUEST,
      'Invalid id field'
    )
  
  null  # Valid request

# Process single JSON-RPC request
processRequest = (request, callback) ->
  # Validate request structure
  validationError = validateRequest(request)
  if validationError
    return callback(validationError)
  
  # Check if method exists
  method = methods[request.method]
  unless method
    return callback createErrorResponse(
      request.id,
      ERROR_CODES.METHOD_NOT_FOUND,
      "Method '#{request.method}' not found"
    )
  
  # Execute method
  try
    method request.params or {}, (error, result) ->
      if error
        callback createErrorResponse(
          request.id,
          error.code or ERROR_CODES.INTERNAL_ERROR,
          error.message,
          error.data
        )
      else
        # Notifications don't get responses
        if request.id?
          callback createSuccessResponse(request.id, result)
        else
          callback null
  
  catch err
    callback createErrorResponse(
      request.id,
      ERROR_CODES.INTERNAL_ERROR,
      err.message
    )

# Process JSON-RPC request (single or batch)
processJsonRpc = (requestBody, callback) ->
  # Parse JSON
  try
    request = JSON.parse(requestBody)
  catch parseError
    return callback createErrorResponse(
      null,
      ERROR_CODES.PARSE_ERROR,
      'Parse error'
    )
  
  # MCP doesn't support batch requests
  if Array.isArray(request)
    return callback createErrorResponse(
      null,
      ERROR_CODES.INVALID_REQUEST,
      'Batch requests not supported by MCP'
    )
  
  # Single request
  processRequest request, callback

module.exports = {
  processJsonRpc
  createErrorResponse
  createSuccessResponse
  ERROR_CODES
}
