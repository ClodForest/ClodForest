# FILENAME: { ClodForest/cake/services/freebsd.coffee }
# FreeBSD rc.d service installer

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
  logger.log 'Installing FreeBSD rc.d service...'
  
  user = process.env.SUDO_USER or os.userInfo().username
  workingDir = paths.root
  coffeePath = getCoffeePath()
  entryPoint = path.relative workingDir, paths.entryPoint
  
  templatePath = path.join paths.templates, 'freebsd.rc'
  rcScript = await renderTemplate templatePath, {
    user
    workingDir
    coffeePath
    entryPoint
  }
  
  tempFile = '/tmp/clodforest'
  await fs.writeFile tempFile, rcScript
  
  await runOrFail "sudo cp #{tempFile} /usr/local/etc/rc.d/clodforest"
  await runOrFail 'sudo chmod +x /usr/local/etc/rc.d/clodforest'
  
  logger.success 'FreeBSD rc.d script installed'
  logger.info 'Enable with: echo \'clodforest_enable="YES"\' | sudo tee -a /etc/rc.conf'
  logger.info 'Start with: sudo service clodforest start'

module.exports = {install}