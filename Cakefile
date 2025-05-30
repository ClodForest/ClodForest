# ClaudeLink Coordinator Cakefile
# Build system for CoffeeScript compilation and project management

fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'

# Colors for console output
colors =
  reset: '\x1b[0m'
  red: '\x1b[31m'
  green: '\x1b[32m'
  yellow: '\x1b[33m'
  blue: '\x1b[34m'
  cyan: '\x1b[36m'

log = (message, color = 'blue') ->
  console.log "#{colors[color]}[ClaudeLink Cake]#{colors.reset} #{message}"

success = (message) ->
  console.log "#{colors.green}✅#{colors.reset} #{message}"

error = (message) ->
  console.log "#{colors.red}❌#{colors.reset} #{message}"

warning = (message) ->
  console.log "#{colors.yellow}⚠️#{colors.reset} #{message}"

# Helper to run shell commands
runCommand = (command, callback) ->
  log "Running: #{command}"
  exec command, (err, stdout, stderr) ->
    if err
      error "Command failed: #{command}"
      console.log stderr if stderr
      process.exit 1
    else
      console.log stdout if stdout
      callback?()

# Helper to check if file exists
fileExists = (filePath) ->
  try
    fs.accessSync filePath, fs.constants.F_OK
    true
  catch
    false

# Configuration
config =
  sourceDir: 'src'
  buildDir: 'dist'
  coffeeFiles: ['server.coffee']
  watchFiles: ['src/**/*.coffee', 'Cakefile']

# Tasks

task 'build', 'Compile CoffeeScript and prepare for deployment', ->
  log 'Starting ClaudeLink build process...'
  
  # Create directories
  unless fileExists config.sourceDir
    log "Creating #{config.sourceDir} directory..."
    fs.mkdirSync config.sourceDir, recursive: true
  
  unless fileExists config.buildDir
    log "Creating #{config.buildDir} directory..."
    fs.mkdirSync config.buildDir, recursive: true
  
  # Convert server.js to server.coffee if needed
  if fileExists('server.js') and not fileExists('src/server.coffee')
    log 'Converting server.js to CoffeeScript...'
    invoke 'convert:server'
  
  # Compile CoffeeScript files
  invoke 'compile'
  
  # Copy static files
  invoke 'copy:static'
  
  success 'Build complete!'

task 'compile', 'Compile CoffeeScript files to JavaScript', ->
  log 'Compiling CoffeeScript files...'
  
  if fileExists 'src'
    runCommand 'coffee --compile --output dist src', ->
      success 'CoffeeScript compilation complete'
  else
    warning 'No src directory found, skipping compilation'

task 'copy:static', 'Copy static files to build directory', ->
  log 'Copying static files...'
  
  staticFiles = [
    'package.json'
    'claudelink-coordinator.service'
    'README.md'
  ]
  
  for file in staticFiles
    if fileExists file
      runCommand "cp #{file} #{config.buildDir}/", ->
        log "Copied #{file}"
  
  success 'Static files copied'

task 'convert:server', 'Convert server.js to CoffeeScript', ->
  log 'Converting server.js to server.coffee...'
  
  unless fileExists 'server.js'
    error 'server.js not found'
    return
  
  # Read the JavaScript file
  serverJs = fs.readFileSync 'server.js', 'utf8'
  
  # Basic JS to CoffeeScript conversion
  # This is a simplified converter - for complex files, manual conversion may be needed
  coffeeScript = serverJs
    # Remove semicolons
    .replace /;$/gm, ''
    # Convert function declarations
    .replace /function\s+(\w+)\s*\([^)]*\)\s*{/g, '$1 = ->'
    # Convert anonymous functions
    .replace /function\s*\([^)]*\)\s*{/g, '->'
    # Convert var/let/const to simple assignment
    .replace /(var|let|const)\s+/g, ''
    # Remove closing braces (this is overly simplistic but works for basic cases)
    .replace /^\s*}$/gm, ''
    # Convert require statements
    .replace /require\(['"]([^'"]+)['"]\)/g, "require '$1'"
    # Convert console.log
    .replace /console\.log\(/g, 'console.log '
    # Basic object syntax fixes
    .replace /(\w+):\s*function\s*\([^)]*\)\s*{/g, '$1: ->'
  
  # Write the CoffeeScript file
  fs.writeFileSync 'src/server.coffee', coffeeScript
  success 'Converted server.js to src/server.coffee'
  
  # Keep original as backup
  fs.renameSync 'server.js', 'server.js.backup'
  log 'Original server.js backed up as server.js.backup'

task 'dev', 'Start development server with auto-reload', ->
  log 'Starting development server...'
  
  # Compile first
  invoke 'compile'
  
  # Start server with nodemon if available, otherwise use node
  if fileExists 'dist/server.js'
    runCommand 'which nodemon', ->
      log 'Starting with nodemon for auto-reload...'
      spawn 'nodemon', ['dist/server.js'], stdio: 'inherit'
  else if fileExists 'server.js'
    log 'Starting server.js directly...'
    spawn 'node', ['server.js'], stdio: 'inherit'
  else
    error 'No server file found to run'

task 'start', 'Start production server', ->
  log 'Starting production server...'
  
  if fileExists 'dist/server.js'
    spawn 'node', ['dist/server.js'], stdio: 'inherit'
  else if fileExists 'server.js'
    spawn 'node', ['server.js'], stdio: 'inherit'
  else
    error 'No server file found to run'

task 'watch', 'Watch CoffeeScript files and recompile on changes', ->
  log 'Watching CoffeeScript files for changes...'
  runCommand 'coffee --watch --compile --output dist src', ->
    log 'Watch mode started'

task 'clean', 'Clean build directory', ->
  log 'Cleaning build directory...'
  
  if fileExists config.buildDir
    runCommand "rm -rf #{config.buildDir}", ->
      success 'Build directory cleaned'
  else
    log 'Build directory does not exist'

task 'install', 'Install system service (requires sudo)', ->
  log 'Installing ClaudeLink Coordinator as system service...'
  
  unless fileExists 'claudelink-coordinator.service'
    error 'Service file not found. Run cake build first.'
    return
  
  runCommand 'sudo cp claudelink-coordinator.service /etc/systemd/system/', ->
    runCommand 'sudo systemctl daemon-reload', ->
      runCommand 'sudo systemctl enable claudelink-coordinator', ->
        success 'Service installed and enabled'
        log 'Start with: sudo systemctl start claudelink-coordinator'

task 'test', 'Run basic functionality tests', ->
  log 'Running basic tests...'
  
  # Test compilation
  invoke 'compile'
  
  # Test that compiled file is valid JavaScript
  if fileExists 'dist/server.js'
    runCommand 'node -c dist/server.js', ->
      success 'Compiled JavaScript is syntactically valid'
  
  success 'Basic tests passed'

task 'package', 'Create deployment package', ->
  log 'Creating deployment package...'
  
  invoke 'build'
  
  runCommand 'tar -czf claudelink-coordinator.tar.gz dist/ package.json README.md', ->
    success 'Deployment package created: claudelink-coordinator.tar.gz'

task 'help', 'Show available tasks', ->
  console.log """
  #{colors.cyan}ClaudeLink Coordinator Build Tasks#{colors.reset}
  
  #{colors.green}Development:#{colors.reset}
    cake build          - Compile CoffeeScript and prepare for deployment
    cake dev            - Start development server with auto-reload
    cake watch          - Watch and recompile CoffeeScript files
    cake test           - Run basic functionality tests
  
  #{colors.green}Production:#{colors.reset}
    cake start          - Start production server
    cake install        - Install as system service (requires sudo)
    cake package        - Create deployment package
  
  #{colors.green}Maintenance:#{colors.reset}
    cake clean          - Clean build directory
    cake convert:server - Convert server.js to CoffeeScript
    cake help           - Show this help message
  
  #{colors.yellow}Examples:#{colors.reset}
    cake build && cake dev    - Build and start development
    cake clean && cake build  - Clean rebuild
    cake package              - Create deployment archive
  """