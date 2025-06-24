# APIs Module Tests

kava = require 'kava'
fs = require 'fs'
path = require 'path'
apis = require '../src/coordinator/lib/apis'

kava.suite 'APIs Module', (suite, test) ->

  test 'should export all required API functions', (done) ->
    requiredFunctions = [
      'getWelcomeData', 'getHealthData', 'getTimeData', 'getRepositoryData',
      'browseRepository', 'readRepositoryFile', 'executeGitCommand',
      'processContextUpdate', 'getInstancesData', 'registerInstance',
      'generateAdminHTML'
    ]
    
    for func in requiredFunctions
      if typeof apis[func] isnt 'function'
        return done(new Error("Missing or invalid API function: #{func}"))
    
    done()

  test 'getWelcomeData should return valid structure', (done) ->
    data = apis.getWelcomeData()
    
    requiredKeys = ['service', 'version', 'status', 'description', 'timestamp', 'endpoints', 'features', 'documentation', 'support']
    
    for key in requiredKeys
      if not data.hasOwnProperty(key)
        return done(new Error("Missing welcome data key: #{key}"))
    
    if data.status isnt 'operational'
      return done(new Error("Invalid status: #{data.status}"))
    
    if not Array.isArray(data.features) or data.features.length is 0
      return done(new Error('Features must be a non-empty array'))
    
    done()

  test 'getHealthData should return valid health information', (done) ->
    data = apis.getHealthData()
    
    requiredKeys = ['status', 'timestamp', 'uptime', 'memory', 'environment', 'services']
    
    for key in requiredKeys
      if not data.hasOwnProperty(key)
        return done(new Error("Missing health data key: #{key}"))
    
    if data.status isnt 'healthy'
      return done(new Error("Invalid health status: #{data.status}"))
    
    # Check memory structure
    memoryKeys = ['rss', 'heapUsed', 'heapTotal']
    for memKey in memoryKeys
      if not data.memory.hasOwnProperty(memKey)
        return done(new Error("Missing memory key: #{memKey}"))
    
    done()

  test 'getTimeData should return valid time information', (done) ->
    mockReq = 
      get: (header) -> 
        if header is 'X-ClaudeLink-Instance' then 'test-instance' else null
    
    data = apis.getTimeData(mockReq)
    
    requiredKeys = ['timestamp', 'unix', 'timezone', 'formats', 'requestor']
    
    for key in requiredKeys
      if not data.hasOwnProperty(key)
        return done(new Error("Missing time data key: #{key}"))
    
    if data.timezone isnt 'UTC'
      return done(new Error("Invalid timezone: #{data.timezone}"))
    
    if data.requestor isnt 'test-instance'
      return done(new Error("Invalid requestor: #{data.requestor}"))
    
    # Validate timestamp format
    if not /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(data.timestamp)
      return done(new Error("Invalid timestamp format: #{data.timestamp}"))
    
    done()

  test 'getRepositoryData should handle repository access', (done) ->
    data = apis.getRepositoryData()
    
    # Should have either repositories or error
    if data.error
      # Error case - check error structure
      if not data.message or not data.timestamp
        return done(new Error('Invalid error response structure'))
    else
      # Success case - check success structure
      requiredKeys = ['repositories', 'count', 'path', 'server', 'timestamp']
      for key in requiredKeys
        if not data.hasOwnProperty(key)
          return done(new Error("Missing repository data key: #{key}"))
      
      if not Array.isArray(data.repositories)
        return done(new Error('Repositories must be an array'))
      
      if data.count isnt data.repositories.length
        return done(new Error('Count mismatch with repositories array'))
    
    done()

  test 'processContextUpdate should return valid response', (done) ->
    mockReq = 
      get: (header) -> 
        if header is 'X-ClaudeLink-Instance' then 'test-instance' else null
      body:
        requestor: 'test-requestor'
        requests: ['request1', 'request2']
    
    data = apis.processContextUpdate(mockReq)
    
    requiredKeys = ['status', 'requestor', 'requestCount', 'timestamp', 'message']
    
    for key in requiredKeys
      if not data.hasOwnProperty(key)
        return done(new Error("Missing context update key: #{key}"))
    
    if data.status isnt 'received'
      return done(new Error("Invalid status: #{data.status}"))
    
    if data.requestCount isnt 2
      return done(new Error("Invalid request count: #{data.requestCount}"))
    
    done()

  test 'getInstancesData should return valid instances data', (done) ->
    data = apis.getInstancesData()
    
    requiredKeys = ['instances', 'count', 'timestamp']
    
    for key in requiredKeys
      if not data.hasOwnProperty(key)
        return done(new Error("Missing instances data key: #{key}"))
    
    if not Array.isArray(data.instances)
      return done(new Error('Instances must be an array'))
    
    if data.count isnt data.instances.length
      return done(new Error('Count mismatch with instances array'))
    
    done()

  test 'registerInstance should store instance data', (done) ->
    # Get initial count to account for any existing instances
    initialData = apis.getInstancesData()
    initialCount = initialData.count
    
    testInstance = 
      id: 'test-instance-123'
      name: 'Test Instance'
      version: '1.0.0'
    
    # Register the instance
    apis.registerInstance(testInstance)
    
    # Check if it's stored
    data = apis.getInstancesData()
    
    if data.count isnt initialCount + 1
      return done(new Error("Expected #{initialCount + 1} instances, got #{data.count}"))
    
    # Find our test instance
    storedInstance = data.instances.find (inst) -> inst.id is testInstance.id
    
    if not storedInstance
      return done(new Error("Test instance not found"))
    
    if storedInstance.id isnt testInstance.id
      return done(new Error("Instance ID mismatch"))
    
    if not storedInstance.lastSeen
      return done(new Error("Missing lastSeen timestamp"))
    
    done()

  test 'generateAdminHTML should return valid HTML', (done) ->
    html = apis.generateAdminHTML()
    
    if typeof html isnt 'string'
      return done(new Error('Admin HTML must be a string'))
    
    if not html.includes('<!DOCTYPE html>')
      return done(new Error('Invalid HTML structure'))
    
    if not html.includes('ClodForest Admin')
      return done(new Error('Missing admin title'))
    
    # Check for key sections
    requiredSections = ['Service Status', 'Repository Management', 'Instance Coordination', 'Context Updates']
    for section in requiredSections
      if not html.includes(section)
        return done(new Error("Missing admin section: #{section}"))
    
    done()

  test 'executeGitCommand should validate allowed commands', (done) ->
    apis.executeGitCommand 'test-repo', 'rm', ['-rf', '/'], (result) ->
      if not result.error
        return done(new Error('Should reject dangerous git command'))
      
      if not result.error.includes('not allowed')
        return done(new Error('Should specify command not allowed'))
      
      done()

  test 'executeGitCommand should accept allowed commands', (done) ->
    apis.executeGitCommand 'test-repo', 'status', [], (result) ->
      # Should not reject the command (though it may fail due to missing repo)
      if result.error and result.error.includes('not allowed')
        return done(new Error('Should accept allowed git command'))
      
      # Check result structure
      requiredKeys = ['repository', 'command', 'args', 'timestamp']
      for key in requiredKeys
        if not result.hasOwnProperty(key)
          return done(new Error("Missing git result key: #{key}"))
      
      done()
