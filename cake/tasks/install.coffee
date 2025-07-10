# FILENAME: { ClodForest/cake/tasks/install.coffee }
# Service installation orchestrator

platform = require '../lib/platform'
logger   = require '../lib/logger'

install = ->
  logger.log 'Installing ClodForest as system service...'

  detected = platform.detect()
  logger.log "Detected platform: #{detected}"

  installer = switch detected
    when 'systemd'        then require '../services/systemd'
    when 'freebsd'        then require '../services/freebsd'
    when 'devuan', 'sysv' then require '../services/sysv'
    when 'macos'
      logger.warning 'macOS service installation not yet implemented'
      logger.info    'Consider using launchd or running manually'
      null
    else
      logger.warning "Unsupported platform for service installation: #{detected}"
      logger.info    'Manual setup required'
      null

  unless installer
    return

  await installer.install()

module.exports = {install}
