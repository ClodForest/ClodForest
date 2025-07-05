# ClodForest Configuration Module
# Centralized environment variable management and defaults

# Server configuration
PORT         = process.env.PORT         or 8080
NODE_ENV     = process.env.NODE_ENV     or 'development'
LOG_LEVEL    = process.env.LOG_LEVEL    or 'info'

# Logging configuration
LOG_DIR      = process.env.LOG_DIR      or './logs'
LOG_ROTATION = process.env.LOG_ROTATION or 'daily'  # daily, size, none
TRUST_PROXY  = process.env.TRUST_PROXY  is 'true' or true  # Default true for load balancer

# Service identification
VAULT_SERVER = process.env.VAULT_SERVER or 'clodforest.thatsnice.org'
SERVICE_NAME = process.env.SERVICE_NAME or 'ClodForest Coordinator'
VERSION      = process.env.VERSION      or '1.0.0'

# Repository configuration
REPO_PATH    = process.env.REPO_PATH    or './state'

# Security configuration
CORS_ORIGINS = process.env.CORS_ORIGINS?.split(',') or [
  'https://claude.ai'
  'https://*.claude.ai'
  'https://chat.openai.com'
  'https://*.openai.com'
  'http://localhost:3000'
  'http://localhost:8080'
  'http://127.0.0.1:8080'
]

# Git operations whitelist
ALLOWED_GIT_COMMANDS = [
  'status'
  'log'
  'diff'
  'branch'
  'pull'
  'push'
  'checkout'
]

# API configuration
API_PATHS =
  BASE:       '/api'
  HEALTH:     '/api/health'
  TIME:       '/api/time'
  REPO:       '/api/repo'
  BUSTIT:     '/api/bustit'
  CONTEXT:    '/api/context'
  INSTANCES:  '/api/instances'
  MCP:        '/api/mcp'
  CONFIG:     '/api/config'

  ADMIN:      '/admin'
  OAUTH:      '/oauth'

# Response format configuration
RESPONSE_FORMATS =
  DEFAULT_TYPE: 'application/json'  # Changed from YAML to JSON as default
  YAML_TYPE:    'application/yaml'
  JSON_TYPE:    'application/json'
  HTML_TYPE:    'text/html'

# Feature flags
FEATURES =
  YAML_RESPONSES:     true
  CONTEXT_UPDATES:    false  # Not yet implemented
  INSTANCE_TRACKING:  true
  GIT_OPERATIONS:     true
  ADMIN_AUTH:         NODE_ENV is 'production'
  MCP_PROTOCOL:       true
  OAUTH2_AUTH:        true  # Enable OAuth2 by default for Claude.ai MCP integration

# Validation helpers
validateConfig = ->
  errors = []

  unless PORT and Number.isInteger(Number(PORT)) and PORT > 0 and PORT < 65536
    errors.push "Invalid PORT: #{PORT}"

  unless REPO_PATH and typeof REPO_PATH is 'string'
    errors.push "Invalid REPO_PATH: #{REPO_PATH}"

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

# Get public configuration (safe to expose)
getPublicConfig = ->
  server:
    port:         PORT
    environment:  NODE_ENV
    log_level:    LOG_LEVEL
    service_name: SERVICE_NAME
    version:      VERSION
    vault_server: VAULT_SERVER

  paths:
    repo_path:  REPO_PATH
    api_paths:  API_PATHS

  features:     FEATURES

  security:
    cors_origins:         CORS_ORIGINS
    allowed_git_commands: ALLOWED_GIT_COMMANDS

  response_formats: RESPONSE_FORMATS

  environment:
    is_development: NODE_ENV isnt 'production'
    is_production:  NODE_ENV is 'production'
    debug_mode:     LOG_LEVEL is 'debug'
    runtime:        getEnvironmentInfo()

  timestamp: new Date().toISOString()

# Export all configuration
module.exports = {
  # Core server config
  PORT
  NODE_ENV
  LOG_LEVEL
  VAULT_SERVER
  SERVICE_NAME
  VERSION

  # Logging config
  LOG_DIR
  LOG_ROTATION
  TRUST_PROXY

  # Paths and storage
  REPO_PATH
  API_PATHS

  # Security
  CORS_ORIGINS
  ALLOWED_GIT_COMMANDS

  # Response handling
  RESPONSE_FORMATS

  # Features
  FEATURES

  # Helpers
  validateConfig
  getEnvironmentInfo
  getPublicConfig

  # Computed properties
  isDevelopment: NODE_ENV  isnt 'production'
  isProduction:  NODE_ENV  is   'production'
  useHttps:      NODE_ENV  is   'production'

  debugMode:     LOG_LEVEL is   'debug'
}
