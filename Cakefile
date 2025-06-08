# ClodForest Coordinator Cakefile
# Streamlined task runner for development and deployment

fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'

# Colors for console output (TODO: Replace with chalk)
colors =
  reset: '\x1b[0m'
  red: '\x1b[31m'
  green: '\x1b[32m'
  yellow: '\x1b[33m'
  blue: '\x1b[34m'
  cyan: '\x1b[36m'

log = (message, color = 'blue') ->
  console.log "#{colors[color]}[ClodForest]#{colors.reset} #{message}"

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

# Platform detection
detectPlatform = ->
  platform = process.platform

  if platform is 'freebsd'
    return 'freebsd'
  else if platform is 'linux'
    # Check for specific distributions
    try
      if fileExists '/etc/devuan_version'
        return 'devuan'
      else if fileExists '/etc/systemd'
        return 'systemd'
      else
        return 'sysv'
    catch
      return 'linux'
  else if platform is 'darwin'
    return 'macos'
  else
    return platform

# Configuration
config =
  entryPoint: 'src/coordinator/index.coffee'
  watchFiles: ['src/**/*.coffee', 'Cakefile']
  configFile: 'config.yaml'

# Tasks

task 'setup', 'Initialize ClodForest configuration', ->
  log 'Setting up ClodForest configuration...'

  unless fileExists config.configFile
    log 'Creating default config.yaml...'

    defaultConfig = """
    # ClodForest Configuration
    # Customize your deployment settings here

    server:
      port: 8080
      vault_server: clodforest-vault
      log_level: info

    repository:
      path: ./state

    features:
      git_operations: true
      admin_auth: false  # Set to true for production
      context_updates: false  # Not yet implemented

    cors:
      origins:
        - https://claude.ai
        - https://*.claude.ai
        - http://localhost:3000
        - http://localhost:8080

    # SSH configuration for Git operations
    ssh:
      key_file: ~/.ssh/clodforest_github
      key_comment: clodforest@thatsnice.org
    """

    fs.writeFileSync config.configFile, defaultConfig
    success 'Created config.yaml - customize as needed'
  else
    log 'config.yaml already exists'

  success 'Setup complete!'

task 'dev', 'Start development server with auto-restart on changes', ->
  log 'Starting development server with auto-restart...'

  unless fileExists config.entryPoint
    error "Entry point not found: #{config.entryPoint}"
    return

  # Check for nodemon
  exec 'which nodemon', (err) ->
    if err
      warning 'nodemon not found - using basic restart'
      log 'Install nodemon globally for better development experience: npm install -g nodemon'

      # Basic file watching with coffee
      log "Starting: coffee #{config.entryPoint}"
      spawn 'coffee', [config.entryPoint],
        stdio: 'inherit'
        env: {
          ...process.env
          NODE_ENV: 'development'
          LOG_LEVEL: 'debug'
        }
    else
      log 'Using nodemon for auto-restart on file changes'
      spawn 'nodemon', [
        '--exec', 'coffee'
        '--watch', 'src/'
        '--ext', 'coffee'
        config.entryPoint
      ],
        stdio: 'inherit'
        env: {
          ...process.env
          NODE_ENV: 'development'
          LOG_LEVEL: 'debug'
        }

task 'start', 'Start production server', ->
  log 'Starting production server...'

  unless fileExists config.entryPoint
    error "Entry point not found: #{config.entryPoint}"
    return

  log "Starting: coffee #{config.entryPoint}"
  spawn 'coffee', [config.entryPoint],
    stdio: 'inherit'
    env: {
      ...process.env
      NODE_ENV: 'production'
    }

task 'install', 'Install ClodForest as system service', ->
  log 'Installing ClodForest as system service...'

  platform = detectPlatform()
  log "Detected platform: #{platform}"

  switch platform
    when 'systemd'
      invoke 'install:systemd'
    when 'freebsd'
      invoke 'install:freebsd'
    when 'devuan'
      invoke 'install:sysv'
    when 'sysv'
      invoke 'install:sysv'
    when 'macos'
      warning 'macOS service installation not yet implemented'
      log 'Consider using launchd or running manually'
    else
      warning "Unsupported platform for service installation: #{platform}"
      log 'Manual setup required'

task 'install:systemd', 'Install systemd service', ->
  log 'Installing systemd service...'

  user = 'ec2-user'
  workingDir = "/home/#{user}/ClodForest"
  coffeePath = "#{workingDir}/node_modules/coffeescript/bin/coffee"

  serviceContent = """
  [Unit]
  Description=ClodForest Coordinator
  After=network.target

  [Service]
  Type=simple
  User=#{user}
  WorkingDirectory=#{workingDir}
  ExecStart=#{coffeePath} src/coordinator/index.coffee
  Restart=always
  RestartSec=10
  Environment=NODE_ENV=production
  Environment=REPO_PATH=./state

  [Install]
  WantedBy=multi-user.target
  """

  fs.writeFileSync '/tmp/clodforest.service', serviceContent

  runCommand 'sudo cp /tmp/clodforest.service /etc/systemd/system/', ->
    runCommand 'sudo systemctl daemon-reload', ->
      runCommand 'sudo systemctl enable clodforest', ->
        success 'Systemd service installed and enabled'
        log 'Start with: sudo systemctl start clodforest'

task 'install:freebsd', 'Install FreeBSD rc.d service', ->
  log 'Installing FreeBSD rc.d service...'

  rcScript = """
  #!/bin/sh
  #
  # PROVIDE: clodforest
  # REQUIRE: LOGIN
  # KEYWORD: shutdown
  #
  # Add the following lines to /etc/rc.conf to enable clodforest:
  # clodforest_enable="YES"
  #

  . /etc/rc.subr

  name="clodforest"
  rcvar=clodforest_enable

  load_rc_config $name

  : ${clodforest_enable="NO"}
  : ${clodforest_user="clodforest"}
  : ${clodforest_dir="/opt/clodforest"}
  : ${clodforest_env="NODE_ENV=production REPO_PATH=./state"}

  pidfile="/var/run/clodforest.pid"
  command="/usr/sbin/daemon"
  command_args="-p ${pidfile} -u ${clodforest_user} /usr/local/bin/coffee ${clodforest_dir}/src/coordinator/index.coffee"

  run_rc_command "$1"
  """

  fs.writeFileSync '/tmp/clodforest', rcScript

  runCommand 'sudo cp /tmp/clodforest /usr/local/etc/rc.d/', ->
    runCommand 'sudo chmod +x /usr/local/etc/rc.d/clodforest', ->
      success 'FreeBSD rc.d script installed'
      log 'Enable with: echo \'clodforest_enable="YES"\' | sudo tee -a /etc/rc.conf'
      log 'Start with: sudo service clodforest start'

task 'install:sysv', 'Install SysV init script', ->
  log 'Installing SysV init script...'

  initScript = """
  #!/bin/bash
  # ClodForest Coordinator init script
  # chkconfig: 35 80 20
  # description: ClodForest Coordinator Service

  . /lib/lsb/init-functions

  USER="clodforest"
  DAEMON="coffee"
  ROOT_DIR="/opt/clodforest"
  SERVER="$ROOT_DIR/src/coordinator/index.coffee"
  PIDFILE="/var/run/clodforest.pid"

  case "$1" in
    start)
      echo -n "Starting ClodForest: "
      start-stop-daemon --start --quiet --pidfile $PIDFILE --make-pidfile \\
        --background --chuid $USER --exec $DAEMON -- $SERVER
      echo "."
      ;;
    stop)
      echo -n "Shutting down ClodForest: "
      start-stop-daemon --stop --quiet --pidfile $PIDFILE
      echo "."
      ;;
    restart)
      $0 stop
      $0 start
      ;;
    *)
      echo "Usage: $0 {start|stop|restart}"
      exit 1
  esac

  exit 0
  """

  fs.writeFileSync '/tmp/clodforest', initScript

  runCommand 'sudo cp /tmp/clodforest /etc/init.d/', ->
    runCommand 'sudo chmod +x /etc/init.d/clodforest', ->
      runCommand 'sudo update-rc.d clodforest defaults', ->
        success 'SysV init script installed'
        log 'Start with: sudo service clodforest start'

task 'test', 'Run basic functionality tests', ->
  log 'Running basic tests...'

  unless fileExists config.entryPoint
    error "Entry point not found: #{config.entryPoint}"
    return

  # Test syntax
  runCommand "coffee -c -p #{config.entryPoint} > /dev/null", ->
    success 'CoffeeScript syntax is valid'

    # TODO: Add more comprehensive tests
    log 'Additional tests will be added as the project grows'

    success 'Basic tests passed'

task 'status', 'Show current project status', ->
  console.log """
  #{colors.cyan}ClodForest Project Status#{colors.reset}

  #{colors.green}Core Files:#{colors.reset}
  """

  # Check entry point
  if fileExists config.entryPoint
    console.log "  ✅ Entry point: #{config.entryPoint}"
  else
    console.log "  ❌ Entry point missing: #{config.entryPoint}"

  # Check modules
  modules = [
    'src/coordinator/lib/config.coffee'
    'src/coordinator/lib/middleware.coffee'
    'src/coordinator/lib/apis.coffee'
    'src/coordinator/lib/routing.coffee'
  ]

  console.log "\n#{colors.green}Modules:#{colors.reset}"
  for module in modules
    if fileExists module
      console.log "  ✅ #{module}"
    else
      console.log "  ❌ #{module}"

  # Check configuration
  console.log "\n#{colors.green}Configuration:#{colors.reset}"
  if fileExists config.configFile
    console.log "  ✅ #{config.configFile}"
  else
    console.log "  ❌ #{config.configFile} (run: cake setup)"

  # Platform info
  platform = detectPlatform()
  console.log "\n#{colors.green}Platform:#{colors.reset}"
  console.log "  📋 Detected: #{platform}"

task 'clean', 'Clean temporary and generated files', ->
  log 'Cleaning temporary files...'

  tempFiles = [
    '/tmp/clodforest'
    '/tmp/clodforest.service'
  ]

  for file in tempFiles
    if fileExists file
      runCommand "rm #{file}", ->
        log "Removed #{file}"

  success 'Cleanup complete'

task 'help', 'Show available tasks', ->
  console.log """
  #{colors.cyan}ClodForest Coordinator Tasks#{colors.reset}

  #{colors.green}Development:#{colors.reset}
    cake setup          - Initialize configuration files
    cake dev            - Start development server with auto-restart
    cake test           - Run basic functionality tests
    cake status         - Show current project status

  #{colors.green}Production:#{colors.reset}
    cake start          - Start production server
    cake install        - Install as system service (auto-detects platform)

  #{colors.green}Platform-Specific Install:#{colors.reset}
    cake install:systemd    - Install systemd service (Linux)
    cake install:freebsd    - Install FreeBSD rc.d service
    cake install:sysv       - Install SysV init script (Devuan/older Linux)

  #{colors.green}Maintenance:#{colors.reset}
    cake clean          - Clean temporary files
    cake help           - Show this help message

  #{colors.yellow}Examples:#{colors.reset}
    cake setup && cake dev      - Initialize and start development
    cake install                - Auto-install for current platform
    cake status                 - Check project health

  #{colors.yellow}Platform Support:#{colors.reset}
    ✅ Linux (systemd)     ✅ FreeBSD     ✅ Devuan/SysV
    ⚠️  macOS (manual)     ❌ Windows
  """
