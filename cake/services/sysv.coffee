# FILENAME: { ClodForest/cake/services/sysv.coffee }
# SysV init script installer

fs = require 'fs/promises'
path = require 'path'
os = require 'os'
{paths, getCoffeePath} = require '../lib/paths'
{runOrFail} = require '../lib/exec'
logger = require '../lib/logger'

renderTemplate = (templatePath, vars) ->
  content = await fs.readFile templatePath, 'utf8'
  for key, value of vars
    content = content.replace new RegExp("\\{\\{#{key}\\}\\}", 'g'), value
  content

install = ->
  logger.log 'Installing SysV init script...'
  
  user = process.env.SUDO_USER or os.userInfo().username
  workingDir = paths.root
  coffeePath = getCoffeePath()
  entryPoint = path.relative workingDir, paths.entryPoint
  
  templatePath = path.join paths.templates, 'sysv.init'
  initScript = await renderTemplate templatePath, {
    user
    workingDir
    coffeePath
    entryPoint
  }
  
  tempFile = '/tmp/clodforest'
  await fs.writeFile tempFile, initScript
  
  await runOrFail "sudo cp #{tempFile} /etc/init.d/clodforest"
  await runOrFail 'sudo chmod +x /etc/init.d/clodforest'
  await runOrFail 'sudo update-rc.d clodforest defaults'
  
  logger.success 'SysV init script installed'
  logger.info 'Start with: sudo service clodforest start'

module.exports = {install}