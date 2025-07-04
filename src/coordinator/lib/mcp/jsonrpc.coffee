# FILENAME: { ClodForest/src/coordinator/lib/mcp/jsonrpc.coffee }
# JSON-RPC 2.0 Protocol Implementation for MCP

methods = require './methods'
logger  = require '../logger'

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
processRequest = (request, req, callback) ->
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
    # Create a wrapper callback to ensure proper error handling
    methodCallback = (error, result) ->
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
    
    # Call method with proper parameters
    method request.params or {}, req, methodCallback
  
  catch err
    callback createErrorResponse(
      request.id,
      ERROR_CODES.INTERNAL_ERROR,
      err.message
    )

# Process JSON-RPC request (single or batch)
processJsonRpc = (requestBody, req, callback) ->
  startTime = Date.now()
  
  # Parse JSON
  try
    request = JSON.parse(requestBody)
  catch parseError
    # Log parse error
    logger.logMCP req, 'mcp_error',
      error_type: 'parse_error'
      error_code: ERROR_CODES.PARSE_ERROR
      error_message: 'Parse error'
      response_time_ms: Date.now() - startTime
    
    return callback createErrorResponse(
      null,
      ERROR_CODES.PARSE_ERROR,
      'Parse error'
    )
  
  # MCP doesn't support batch requests
  if Array.isArray(request)
    # Log batch request error
    logger.logMCP req, 'mcp_error',
      error_type: 'batch_not_supported'
      error_code: ERROR_CODES.INVALID_REQUEST
      error_message: 'Batch requests not supported by MCP'
      response_time_ms: Date.now() - startTime
    
    return callback createErrorResponse(
      null,
      ERROR_CODES.INVALID_REQUEST,
      'Batch requests not supported by MCP'
    )
  
  # Log incoming request
  logger.logMCP req, 'mcp_request',
    method: request.method
    request_id: request.id
    params: request.params
  
  # Single request
  processRequest request, req, (response) ->
    responseTime = Date.now() - startTime
    
    # Log response
    if response?.error
      logger.logMCP req, 'mcp_error',
        method: request.method
        request_id: request.id
        error_code: response.error.code
        error_message: response.error.message
        response_time_ms: responseTime
    else
      logger.logMCP req, 'mcp_response',
        method: request.method
        request_id: request.id
        success: true
        response_time_ms: responseTime
    
    callback(response)

module.exports = {
  processJsonRpc
  createErrorResponse
  createSuccessResponse
  ERROR_CODES
}
