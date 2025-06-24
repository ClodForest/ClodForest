# Integration Tests

kava = require 'kava'
http = require 'http'
path = require 'path'
fs = require 'fs'

kava.suite 'Integration Tests', (suite, test) ->

  # Test the full application startup
  test 'should start application without errors', (done) ->
    try
      # Import the main application
      app = require '../src/coordinator/index'
      
      # Check that app and server are exported
      if not app.app or not app.server
        return done(new Error('Application should export app and server'))
      
      # Check that server is listening
      if not app.server.listening
        return done(new Error('Server should be listening'))
      
      done()
    catch error
      done(error)

  test 'should handle graceful shutdown signals', (done) ->
    # This test verifies that the shutdown handlers are registered
    # We can't easily test the actual shutdown without stopping the server
    
    try
      app = require '../src/coordinator/index'
      
      # Check that process has event listeners for shutdown signals
      listeners = process.listeners('SIGTERM').length + process.listeners('SIGINT').length
      
      if listeners < 2
        return done(new Error('Should have SIGTERM and SIGINT listeners'))
      
      done()
    catch error
      done(error)

  test 'should serve static files from repository path', (done) ->
    try
      config = require '../src/coordinator/lib/config'
      
      # Check if REPO_PATH exists
      if not fs.existsSync(config.REPO_PATH)
        return done(new Error("Repository path should exist: #{config.REPO_PATH}"))
      
      # Check if it's a directory
      stat = fs.statSync(config.REPO_PATH)
      if not stat.isDirectory()
        return done(new Error("Repository path should be a directory: #{config.REPO_PATH}"))
      
      done()
    catch error
      done(error)

  test 'should have consistent configuration across modules', (done) ->
    try
      config = require '../src/coordinator/lib/config'
      apis = require '../src/coordinator/lib/apis'
      
      # Test that APIs use the same configuration
      welcomeData = apis.getWelcomeData()
      
      if welcomeData.service isnt config.SERVICE_NAME
        return done(new Error('Service name mismatch between config and APIs'))
      
      if welcomeData.version isnt config.VERSION
        return done(new Error('Version mismatch between config and APIs'))
      
      done()
    catch error
      done(error)

  test 'should validate all API paths are accessible', (done) ->
    try
      config = require '../src/coordinator/lib/config'
      
      # Check that all API paths are strings and start with /
      for pathName, pathValue of config.API_PATHS
        if typeof pathValue isnt 'string'
          return done(new Error("API path #{pathName} should be a string"))
        
        if not pathValue.startsWith('/')
          return done(new Error("API path #{pathName} should start with /"))
      
      done()
    catch error
      done(error)

  test 'should have valid CORS configuration', (done) ->
    try
      config = require '../src/coordinator/lib/config'
      
      # Check CORS origins
      if not Array.isArray(config.CORS_ORIGINS)
        return done(new Error('CORS_ORIGINS should be an array'))
      
      if config.CORS_ORIGINS.length is 0
        return done(new Error('CORS_ORIGINS should not be empty'))
      
      # Check that each origin is a valid string
      for origin in config.CORS_ORIGINS
        if typeof origin isnt 'string'
          return done(new Error("CORS origin should be a string: #{origin}"))
        
        # Basic URL validation for non-localhost origins
        if not origin.includes('localhost') and not origin.includes('127.0.0.1')
          if not (origin.startsWith('http://') or origin.startsWith('https://') or origin.startsWith('*'))
            return done(new Error("Invalid CORS origin format: #{origin}"))
      
      done()
    catch error
      done(error)

  test 'should have proper error handling in APIs', (done) ->
    try
      apis = require '../src/coordinator/lib/apis'
      
      # Test repository browsing with invalid path
      result = apis.browseRepository('nonexistent-repo', 'invalid/path')
      
      if not result.error
        return done(new Error('Should return error for invalid repository path'))
      
      if not result.timestamp
        return done(new Error('Error response should include timestamp'))
      
      done()
    catch error
      done(error)

  test 'should handle file operations safely', (done) ->
    try
      apis = require '../src/coordinator/lib/apis'
      
      # Test reading non-existent file
      result = apis.readRepositoryFile('test-repo', '../../../etc/passwd')
      
      if not result.error
        return done(new Error('Should return error for dangerous file paths'))
      
      done()
    catch error
      done(error)

  test 'should validate git command security', (done) ->
    try
      apis = require '../src/coordinator/lib/apis'
      config = require '../src/coordinator/lib/config'
      
      # Test that dangerous commands are blocked
      dangerousCommands = ['rm', 'reset --hard', 'clean -fd', 'rebase', 'merge']
      
      for cmd in dangerousCommands
        if cmd in config.ALLOWED_GIT_COMMANDS
          return done(new Error("Dangerous git command should not be allowed: #{cmd}"))
      
      # Test that safe commands are allowed
      safeCommands = ['status', 'log', 'diff', 'branch']
      
      for cmd in safeCommands
        if cmd not in config.ALLOWED_GIT_COMMANDS
          return done(new Error("Safe git command should be allowed: #{cmd}"))
      
      done()
    catch error
      done(error)

  test 'should maintain instance tracking consistency', (done) ->
    try
      apis = require '../src/coordinator/lib/apis'
      
      # Clear any existing instances
      initialData = apis.getInstancesData()
      
      # Register a test instance
      testInstance = 
        id: 'integration-test-instance'
        name: 'Integration Test'
        version: '1.0.0'
      
      apis.registerInstance(testInstance)
      
      # Check that it was registered
      afterRegister = apis.getInstancesData()
      
      if afterRegister.count isnt initialData.count + 1
        return done(new Error('Instance count should increase after registration'))
      
      # Find the registered instance
      found = afterRegister.instances.find (inst) -> inst.id is testInstance.id
      
      if not found
        return done(new Error('Registered instance should be findable'))
      
      if not found.lastSeen
        return done(new Error('Registered instance should have lastSeen timestamp'))
      
      done()
    catch error
      done(error)

  test 'should generate valid admin HTML', (done) ->
    try
      apis = require '../src/coordinator/lib/apis'
      
      html = apis.generateAdminHTML()
      
      # Basic HTML validation
      if not html.includes('<!DOCTYPE html>')
        return done(new Error('Admin HTML should be valid HTML'))
      
      if not html.includes('<html>')
        return done(new Error('Admin HTML should have html tag'))
      
      if not html.includes('</html>')
        return done(new Error('Admin HTML should be properly closed'))
      
      # Check for required sections
      requiredElements = [
        'ClodForest Admin',
        'Service Status',
        'Repository Management',
        'Instance Coordination',
        'Context Updates'
      ]
      
      for element in requiredElements
        if not html.includes(element)
          return done(new Error("Admin HTML should contain: #{element}"))
      
      done()
    catch error
      done(error)
