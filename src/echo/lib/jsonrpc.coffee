# FILENAME: { ClodForest/src/echo/lib/jsonrpc.coffee }
# JSON-RPC 2.0 Protocol Implementation

config = require './config'
echo   = require '../methods/echo'

# JSON-RPC Error Codes
ERROR_CODES =
  PARSE_ERROR:      -32700
  INVALID_REQUEST:  -32600
  METHOD_NOT_FOUND: -32601
  INVALID_PARAMS:   -32602
  INTERNAL_ERROR:   -32603

# Available methods
METHODS =
  'echo.simple':   echo.simple
  'echo.enhanced': echo.enhanced
  'echo.delay':    echo.delay
  'echo.error':    echo.error

# Create JSON-RPC error response
createErrorResponse = (id, code, message, data = null) ->
  response =
    jsonrpc: config.JSONRPC_VERSION
    error:
      code:    code
      message: message
    id: id
  
  if data
    response.error.data = data
  
  response

# Create JSON-RPC success response
createSuccessResponse = (id, result) ->
  jsonrpc: config.JSONRPC_VERSION
  result:  result
  id:      id

# Validate JSON-RPC request structure
validateRequest = (request) ->
  # Check required fields
  unless request.jsonrpc is config.JSONRPC_VERSION
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
  
  # ID can be string, number, or null, but not undefined
  unless request.hasOwnProperty('id')
    return createErrorResponse(
      null,
      ERROR_CODES.INVALID_REQUEST,
      'Missing id field'
    )
  
  null  # Valid request

# Process single JSON-RPC request
processRequest = (request, callback) ->
  # Validate request structure
  validationError = validateRequest(request)
  if validationError
    return callback(validationError)
  
  # Check if method exists
  method = METHODS[request.method]
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
          ERROR_CODES.INTERNAL_ERROR,
          error.message,
          error.data
        )
      else
        callback createSuccessResponse(request.id, result)
  
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
  
  # Handle batch requests
  if Array.isArray(request)
    unless config.FEATURES.BATCH_REQUESTS
      return callback createErrorResponse(
        null,
        ERROR_CODES.INVALID_REQUEST,
        'Batch requests not supported'
      )
    
    if request.length is 0
      return callback createErrorResponse(
        null,
        ERROR_CODES.INVALID_REQUEST,
        'Empty batch request'
      )
    
    # Process each request in batch
    responses = []
    completed = 0
    
    for req, index in request
      processRequest req, (response) ->
        responses[index] = response
        completed++
        
        if completed is request.length
          # Filter out null responses (notifications)
          validResponses = responses.filter (r) -> r isnt null
          callback if validResponses.length > 0 then validResponses else null
  
  else
    # Single request
    processRequest request, callback

module.exports = {
  processJsonRpc
  createErrorResponse
  createSuccessResponse
  ERROR_CODES
}
