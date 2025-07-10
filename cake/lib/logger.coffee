# FILENAME: { ClodForest/cake/lib/logger.coffee }
# Simple logging utilities without dependencies

log = (message) ->
  console.log "[ClodForest] #{message}"

success = (message) ->
  console.log "✅ #{message}"

error = (message) ->
  console.log "❌ #{message}"

warning = (message) ->
  console.log "⚠️ #{message}"

info = (message) ->
  console.log "ℹ #{message}"

debug = (message) ->
  console.log "[DEBUG] #{message}" if process.env.DEBUG

module.exports = {
  log
  success
  error
  warning
  info
  debug
}