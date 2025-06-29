# FILENAME: { ClodForest/src/echo/methods/echo.coffee }
# Echo method implementations for JSON-RPC server

config = require '../lib/config'

# Simple echo - returns exactly what was sent
simple = (params, callback) ->
  callback null, params

# Enhanced echo - returns params plus metadata
enhanced = (params, callback) ->
  result =
    echo:      params
    metadata:
      timestamp: new Date().toISOString()
      server:    config.SERVICE_NAME
      version:   config.VERSION
      method:    'echo.enhanced'
      
  callback null, result

# Delayed echo - echoes after specified delay
delay = (params, callback) ->
  unless config.FEATURES.DELAY_METHOD
    return callback new Error('Delay method disabled')
  
  delayMs = params.delay_ms or 0
  
  # Validate delay parameter
  unless typeof delayMs is 'number' and delayMs >= 0 and delayMs <= 10000
    return callback new Error('Invalid delay_ms: must be number between 0-10000')
  
  setTimeout ->
    result =
      echo:     params
      delayed:  delayMs
      executed: new Date().toISOString()
    
    callback null, result
  , delayMs

# Error echo - intentionally returns error for testing
error = (params, callback) ->
  unless config.FEATURES.ERROR_METHOD
    return callback new Error('Error method disabled')
  
  errorType = params.error_type or 'generic'
  
  switch errorType
    when 'generic'
      callback new Error('Intentional test error')
    
    when 'custom'
      error = new Error(params.message or 'Custom error message')
      error.data = params.data if params.data
      callback error
    
    when 'timeout'
      # Simulate timeout by not calling callback
      return
    
    else
      callback new Error("Unknown error_type: #{errorType}")

module.exports = {
  simple
  enhanced
  delay
  error
}
