# FILENAME: { ClodForest/src/echo/lib/config.coffee }
# JSON-RPC Echo Server Configuration

# Server configuration
PORT     = process.env.ECHO_PORT or process.env.PORT or 8081
NODE_ENV = process.env.NODE_ENV  or 'development'

# Service identification
SERVICE_NAME = 'JSON-RPC Echo Server'
VERSION      = '1.0.0'

# CORS configuration
CORS_ORIGINS = [
  'https://claude.ai'
  'https://*.claude.ai'
  'https://chat.openai.com'
  'https://*.openai.com'
  'http://localhost:3000'
  'http://localhost:8080'
  'http://127.0.0.1:8080'
]

# JSON-RPC configuration
JSONRPC_VERSION = '2.0'
MAX_REQUEST_SIZE = 1024 * 1024  # 1MB

# Echo method configuration
ECHO_METHODS =
  SIMPLE:   'echo.simple'
  ENHANCED: 'echo.enhanced'
  DELAY:    'echo.delay'
  ERROR:    'echo.error'

# Feature flags
FEATURES =
  BATCH_REQUESTS: true
  DELAY_METHOD:   true
  ERROR_METHOD:   true
  CORS_ENABLED:   true

# Validation helpers
validateConfig = ->
  errors = []

  unless PORT and Number.isInteger(Number(PORT)) and PORT > 0 and PORT < 65536
    errors.push "Invalid PORT: #{PORT}"

  if errors.length > 0
    console.error 'Configuration validation failed:'
    errors.forEach (error) -> console.error "  - #{error}"
    process.exit 1

# Environment info
getEnvironmentInfo = ->
  node:     process.version
  platform: process.platform
  arch:     process.arch
  env:      NODE_ENV
  uptime:   process.uptime()

# Export all configuration
module.exports = {
  # Core server config
  PORT
  NODE_ENV
  SERVICE_NAME
  VERSION

  # CORS
  CORS_ORIGINS

  # JSON-RPC
  JSONRPC_VERSION
  MAX_REQUEST_SIZE
  ECHO_METHODS

  # Features
  FEATURES

  # Helpers
  validateConfig
  getEnvironmentInfo

  # Computed properties
  isDevelopment: NODE_ENV isnt 'production'
  isProduction:  NODE_ENV is 'production'
}
