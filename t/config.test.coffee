# Configuration Module Tests

kava = require 'kava'
config = require '../src/coordinator/lib/config'

kava.suite 'Configuration Module', (suite, test) ->

  test 'should export all required configuration values', (done) ->
    requiredKeys = [
      'PORT', 'NODE_ENV', 'LOG_LEVEL', 'VAULT_SERVER', 'SERVICE_NAME', 'VERSION',
      'REPO_PATH', 'API_PATHS', 'CORS_ORIGINS', 'ALLOWED_GIT_COMMANDS',
      'RESPONSE_FORMATS', 'FEATURES', 'validateConfig', 'getEnvironmentInfo',
      'isDevelopment', 'isProduction', 'debugMode'
    ]
    
    for key in requiredKeys
      if not config.hasOwnProperty(key)
        return done(new Error("Missing configuration key: #{key}"))
    
    done()

  test 'should have valid PORT configuration', (done) ->
    port = config.PORT
    if typeof port is 'string'
      port = parseInt(port, 10)
    
    if not Number.isInteger(port) or port <= 0 or port >= 65536
      return done(new Error("Invalid PORT: #{config.PORT}"))
    
    done()

  test 'should have valid API_PATHS configuration', (done) ->
    paths = config.API_PATHS
    requiredPaths = ['BASE', 'HEALTH', 'TIME', 'REPO', 'BUSTIT', 'CONTEXT', 'INSTANCES', 'ADMIN']
    
    for pathKey in requiredPaths
      if not paths[pathKey] or typeof paths[pathKey] isnt 'string'
        return done(new Error("Missing or invalid API path: #{pathKey}"))
    
    done()

  test 'should have valid CORS_ORIGINS array', (done) ->
    origins = config.CORS_ORIGINS
    
    if not Array.isArray(origins)
      return done(new Error('CORS_ORIGINS must be an array'))
    
    if origins.length is 0
      return done(new Error('CORS_ORIGINS cannot be empty'))
    
    for origin in origins
      if typeof origin isnt 'string'
        return done(new Error("Invalid CORS origin: #{origin}"))
    
    done()

  test 'should have valid ALLOWED_GIT_COMMANDS array', (done) ->
    commands = config.ALLOWED_GIT_COMMANDS
    
    if not Array.isArray(commands)
      return done(new Error('ALLOWED_GIT_COMMANDS must be an array'))
    
    expectedCommands = ['status', 'log', 'diff', 'branch', 'pull', 'push', 'checkout']
    for cmd in expectedCommands
      if cmd not in commands
        return done(new Error("Missing git command: #{cmd}"))
    
    done()

  test 'should have valid FEATURES configuration', (done) ->
    features = config.FEATURES
    requiredFeatures = ['YAML_RESPONSES', 'CONTEXT_UPDATES', 'INSTANCE_TRACKING', 'GIT_OPERATIONS', 'ADMIN_AUTH']
    
    for feature in requiredFeatures
      if not features.hasOwnProperty(feature) or typeof features[feature] isnt 'boolean'
        return done(new Error("Missing or invalid feature flag: #{feature}"))
    
    done()

  test 'should provide environment info', (done) ->
    envInfo = config.getEnvironmentInfo()
    requiredKeys = ['node', 'platform', 'arch', 'env', 'uptime']
    
    for key in requiredKeys
      if not envInfo.hasOwnProperty(key)
        return done(new Error("Missing environment info key: #{key}"))
    
    done()

  test 'should correctly determine development/production mode', (done) ->
    # Test that boolean flags are consistent
    if config.isDevelopment is config.isProduction
      return done(new Error('isDevelopment and isProduction cannot both be true or false'))
    
    # Test that they match NODE_ENV
    if config.NODE_ENV is 'production'
      if not config.isProduction or config.isDevelopment
        return done(new Error('Production mode flags inconsistent'))
    else
      if config.isProduction or not config.isDevelopment
        return done(new Error('Development mode flags inconsistent'))
    
    done()

  test 'should have valid RESPONSE_FORMATS', (done) ->
    formats = config.RESPONSE_FORMATS
    requiredFormats = ['DEFAULT_TYPE', 'YAML_TYPE', 'JSON_TYPE', 'HTML_TYPE']
    
    for format in requiredFormats
      if not formats[format] or typeof formats[format] isnt 'string'
        return done(new Error("Missing or invalid response format: #{format}"))
    
    done()
