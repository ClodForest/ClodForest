# FILENAME: { ClodForest/cake/services/systemd.coffee }
# Systemd service installer

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
  logger.log 'Installing systemd service...'
  
  # Determine user and paths
  user = process.env.SUDO_USER or os.userInfo().username
  workingDir = paths.root
  coffeePath = getCoffeePath()
  entryPoint = path.relative workingDir, paths.entryPoint
  
  # Render service file
  templatePath = path.join paths.templates, 'systemd.service'
  serviceContent = await renderTemplate templatePath, {
    user
    workingDir
    coffeePath
    entryPoint
  }
  
  # Write to temp and copy
  tempFile = '/tmp/clodforest.service'
  await fs.writeFile tempFile, serviceContent
  
  await runOrFail "sudo cp #{tempFile} /etc/systemd/system/clodforest.service"
  await runOrFail 'sudo systemctl daemon-reload'
  await runOrFail 'sudo systemctl enable clodforest'
  
  logger.success 'Systemd service installed and enabled'
  logger.info 'Start with: sudo systemctl start clodforest'
  logger.info 'View logs with: sudo journalctl -u clodforest -f'

module.exports = {install}