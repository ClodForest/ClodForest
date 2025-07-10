# FILENAME: { ClodForest/cake/tasks/test.coffee }
# Testing tasks

{paths, validate} = require '../lib/paths'
{run, runOrFail} = require '../lib/exec'
logger = require '../lib/logger'

runTests = ->
  logger.log 'Running tests...'

  # Validate syntax first
  validate paths.entryPoint, 'Entry point'

  try
    await run "coffee -p #{paths.entryPoint} > /dev/null"
    logger.success 'CoffeeScript syntax is valid'
  catch
    logger.error 'CoffeeScript syntax errors found'
    process.exit 1

  # Run test suites if they exist
  testFiles = [
    'test/mcp-test.coffee'
    'test/mcp-comprehensive-test.coffee'
    'test/mcp-security-test.coffee'
    'test/oauth-rfc-compliant-test.coffee'
  ]

  for testFile in testFiles
    testPath = "#{paths.root}/#{testFile}"
    if require('../lib/paths').exists testPath
      logger.log "Running #{testFile}..."
      await runOrFail "coffee #{testPath}"

  logger.success 'All tests passed!'

debugMcpInspector = ->
  logger.log 'Starting MCP Inspector OAuth2 debug server on port 3000...'
  logger.info 'Configure MCP Inspector to connect to http://localhost:3000'
  logger.info 'Press Ctrl+C to stop'

  debugScript = "#{paths.test}/scripts/mcp-inspector-oauth-debug.coffee"
  validate debugScript, 'Debug server script'

  {spawn} = require 'child_process'
  spawn require('../lib/paths').getCoffeePath(), [debugScript],
    stdio: 'inherit'
    env: Object.assign {},
      NODE_ENV: 'development'
      PORT:     '3000'
      process.env

module.exports = {
  runTests
  debugMcpInspector
}
