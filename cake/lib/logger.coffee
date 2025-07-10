# FILENAME: { ClodForest/cake/lib/logger.coffee }
# Logging utilities with optional chalk support

# Try to load chalk, fall back to plain text if not available
try
  chalk = require 'chalk'
catch
  # Fallback when chalk is not installed
  chalk =
    blue:   (text) -> text
    green:  (text) -> text
    red:    (text) -> text
    yellow: (text) -> text
    cyan:   (text) -> text
    gray:   (text) -> text

log = (message) ->
  console.log "#{chalk.blue '[ClodForest]'} #{message}"

success = (message) ->
  console.log "#{chalk.green '✅'} #{message}"

error = (message) ->
  console.log "#{chalk.red '❌'} #{message}"

warning = (message) ->
  console.log "#{chalk.yellow '⚠️'} #{message}"

info = (message) ->
  console.log "#{chalk.cyan 'ℹ'} #{message}"

debug = (message) ->
  console.log "#{chalk.gray '[DEBUG]'} #{message}" if process.env.DEBUG

module.exports = {
  log
  success
  error
  warning
  info
  debug
}