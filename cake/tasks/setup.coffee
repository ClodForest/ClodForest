# FILENAME: { ClodForest/cake/tasks/setup.coffee }
# Setup and configuration tasks

fs = require 'fs/promises'
path = require 'path'
{paths, exists} = require '../lib/paths'
logger = require '../lib/logger'

copyTemplate = (templateName, destination) ->
  templatePath = path.join paths.templates, templateName
  templateContent = await fs.readFile templatePath, 'utf8'
  await fs.writeFile destination, templateContent
  logger.success "Created #{path.basename destination}"

setup = ->
  logger.log 'Setting up ClodForest configuration...'
  
  if exists paths.config
    logger.log 'config.yaml already exists'
  else
    await copyTemplate 'config.yaml', paths.config
    logger.info 'Customize config.yaml as needed'
  
  logger.success 'Setup complete!'

module.exports = {setup}