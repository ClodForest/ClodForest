#!/usr/bin/env coffee
# FILENAME: { ClodForest/bin/test-all-rfcs.coffee }
# Comprehensive RFC Compliance Test Runner
# Orchestrates all RFC compliance tests for ClodForest

{spawn} = require 'node:child_process'
path    = require 'node:path'

# Parse command line arguments
args = process.argv.slice(2)
verbose = false
environment = 'local'
exitCode = 0

# Test configuration
testSuites = [
  {
    name: 'RFC 5785 Well-Known URIs'
    script: 'bin/test-well-known.coffee'
    description: 'Tests discovery endpoints and metadata'
    rfc: 'RFC 5785'
  }
  {
    name: 'RFC 6749 OAuth 2.0 Authorization Framework'
    script: 'bin/test-oauth2.coffee'
    description: 'Tests OAuth2 compliance and grant flows'
    rfc: 'RFC 6749, RFC 6750, RFC 8414'
  }
  {
    name: 'MCP 2025-06-18 Specification'
    script: 'bin/test-mcp.coffee'
    description: 'Tests MCP protocol compliance'
    rfc: 'JSON-RPC 2.0, MCP 2025-06-18'
  }
  {
    name: 'OAuth2 + MCP Integration'
    script: 'bin/test-oauth2-mcp.coffee'
    description: 'Tests end-to-end integration compliance'
    rfc: 'Integration Testing'
  }
]

# Parse arguments
showHelp = ->
  console.log '''
    ClodForest Comprehensive RFC Compliance Test Runner

    Usage:
      coffee bin/test-all-rfcs.coffee [options]

    Options:
      --env, -e <environment>    Environment preset (local, production)
      --verbose, -v              Show detailed output from all tests
      --help                     Show this help

    Environment Presets:
      local                      http://localhost:8080 (default)
      production                 https://clodforest.thatsnice.org:443

    Exit Codes:
      0                          All RFC compliance tests passed
      1                          One or more RFC compliance tests failed

    Test Suites:
      • RFC 5785 Well-Known URIs Discovery
      • RFC 6749 OAuth 2.0 Authorization Framework
      • RFC 6750 Bearer Token Usage
      • RFC 8414 OAuth Authorization Server Metadata
      • MCP 2025-06-18 Specification
      • JSON-RPC 2.0 Protocol Compliance
      • Integration Testing

    Examples:
      coffee bin/test-all-rfcs.coffee                    # Test all RFCs (local)
      coffee bin/test-all-rfcs.coffee --verbose          # Test with details
      coffee bin/test-all-rfcs.coffee --env production   # Test production
    '''
  process.exit 0

i = 0
while i < args.length
  arg = args[i]

  switch arg
    when '--help'
      showHelp()

    when '--verbose', '-v'
      verbose = true

    when '--env', '-e'
      environment = args[++i]
      unless environment
        console.error 'Error: --env requires an environment name'
        process.exit 1

    else
      console.error "Error: Unknown option '#{arg}'"
      console.error "Use --help for usage information"
      process.exit 1

  i++

# Logging functions
logInfo = (message) ->
  console.log message

logError = (message) ->
  console.error message
  exitCode = 1

logSuccess = (message) ->
  console.log message

# Test results tracking
testResults = []

# Helper to run a test script
runTest = (testSuite) ->
  new Promise (resolve, reject) ->
    logInfo "\n" + "=".repeat(80)
    logInfo "🧪 Running #{testSuite.name}"
    logInfo "📋 #{testSuite.description}"
    logInfo "📖 Standards: #{testSuite.rfc}"
    logInfo "=".repeat(80)

    # Build command arguments
    cmdArgs = ['--env', environment]
    cmdArgs.push('--verbose') if verbose

    # Spawn the test process
    testProcess = spawn 'coffee', [testSuite.script].concat(cmdArgs), {
      stdio: if verbose then 'inherit' else 'pipe'
      cwd: process.cwd()
    }

    output = ''
    if not verbose
      testProcess.stdout?.on 'data', (data) ->
        output += data.toString()
      
      testProcess.stderr?.on 'data', (data) ->
        output += data.toString()

    testProcess.on 'close', (code) ->
      result = {
        name: testSuite.name
        rfc: testSuite.rfc
        passed: code is 0
        exitCode: code
        output: output
      }

      testResults.push(result)

      if code is 0
        logSuccess "✅ #{testSuite.name} - PASSED"
      else
        logError "❌ #{testSuite.name} - FAILED (exit code: #{code})"
        if not verbose and output
          console.log "\nTest output:"
          console.log output

      resolve(result)

    testProcess.on 'error', (err) ->
      logError "💥 Failed to run #{testSuite.name}: #{err.message}"
      result = {
        name: testSuite.name
        rfc: testSuite.rfc
        passed: false
        exitCode: 1
        error: err.message
      }
      testResults.push(result)
      resolve(result)

# Main test execution
main = ->
  startTime = Date.now()
  
  logInfo "🚀 ClodForest RFC Compliance Test Suite"
  logInfo "Environment: #{environment}"
  logInfo "Verbose: #{verbose}"
  logInfo "Started: #{new Date().toISOString()}"

  try
    # Run all test suites sequentially
    for testSuite in testSuites
      await runTest(testSuite)

    # Generate final report
    endTime = Date.now()
    duration = Math.round((endTime - startTime) / 1000)
    
    logInfo "\n" + "=".repeat(80)
    logInfo "📊 FINAL RFC COMPLIANCE REPORT"
    logInfo "=".repeat(80)

    passedTests = testResults.filter((r) -> r.passed).length
    totalTests = testResults.length
    successRate = Math.round((passedTests / totalTests) * 100)

    logInfo "📈 Overall Results:"
    logInfo "   Tests Passed: #{passedTests}/#{totalTests} (#{successRate}%)"
    logInfo "   Duration: #{duration}s"
    logInfo "   Environment: #{environment}"

    logInfo "\n📋 Individual Test Results:"
    for result in testResults
      status = if result.passed then "✅ PASS" else "❌ FAIL"
      logInfo "   #{status} #{result.name}"
      logInfo "      Standards: #{result.rfc}"
      if result.error
        logInfo "      Error: #{result.error}"

    if passedTests is totalTests
      logInfo "\n🎯 ALL RFC COMPLIANCE TESTS PASSED"
      logInfo "✅ ClodForest is fully compliant with all tested RFCs"
      logInfo "✅ Ready for production deployment"
      process.exit 0
    else
      failedTests = testResults.filter((r) -> not r.passed)
      logInfo "\n⚠️  RFC COMPLIANCE ISSUES DETECTED"
      logInfo "❌ #{failedTests.length} test suite(s) failed"
      logInfo "\nFailed Test Suites:"
      for result in failedTests
        logInfo "• #{result.name} (#{result.rfc})"
      
      logInfo "\n💡 Fix the failing components to achieve full RFC compliance"
      process.exit 1

  catch error
    logError "💥 Test suite execution error: #{error.message}"
    process.exit 1

# Handle process errors
process.on 'uncaughtException', (err) ->
  logError "Uncaught exception: #{err.message}"
  process.exit 1

process.on 'unhandledRejection', (reason, promise) ->
  logError "Unhandled rejection: #{reason}"
  process.exit 1

# Set timeout for entire test suite (10 minutes)
setTimeout ->
  logError "Test suite timeout - tests taking too long to complete"
  process.exit 1
, 600000  # 10 minute timeout

# Run the test suite
main()
