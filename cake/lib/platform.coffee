# FILENAME: { ClodForest/cake/lib/platform.coffee }
# Platform detection utilities

fs = require 'fs'

fileExists = (filePath) ->
  try
    fs.accessSync filePath, fs.constants.F_OK
    true
  catch
    false

detect = ->
  platform = process.platform

  return 'freebsd' if platform is 'freebsd'
  return 'macos'   if platform is 'darwin'
  return 'windows' if platform is 'win32'
  
  if platform is 'linux'
    # Check for specific distributions
    return 'devuan'  if fileExists '/etc/devuan_version'
    return 'systemd' if fileExists '/etc/systemd'
    return 'sysv'
    
  platform

isSystemd = -> detect() is 'systemd'
isFreeBSD = -> detect() is 'freebsd'
isDevuan  = -> detect() is 'devuan'
isSysV    = -> detect() in ['sysv', 'devuan']
isMacOS   = -> detect() is 'macos'
isWindows = -> detect() is 'windows'

module.exports = {
  detect
  isSystemd
  isFreeBSD
  isDevuan
  isSysV
  isMacOS
  isWindows
}