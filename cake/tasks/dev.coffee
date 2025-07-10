# FILENAME: { ClodForest/cake/tasks/dev.coffee }
# Development server tasks

{spawn} = require 'child_process'
{paths, validate, getCoffeePath} = require '../lib/paths'
{run} = require '../lib/exec'
logger = require '../lib/logger'

checkNodemon = ->
  try
    await run 'which nodemon', silent: true
    true
  catch
    false

startDev = ->
  logger.log 'Starting development server with auto-restart...'

  validate paths.entryPoint, 'Entry point'

  hasNodemon = await checkNodemon()

  env =
    NODE_ENV: 'development'
    LOG_LEVEL: 'debug'

  if hasNodemon
    logger.log 'Using nodemon for auto-restart on file changes'
    spawn 'nodemon', [
      '--exec', getCoffeePath()
      '--watch', 'src/'
      '--ext', 'coffee'
      paths.entryPoint
    ],
      stdio: 'inherit'
      env: Object.assign {}, env, process.env
  else
    logger.warning 'nodemon not found - using basic restart'
    logger.info 'Install nodemon globally for better development experience: npm install -g nodemon'

    spawn getCoffeePath(), [paths.entryPoint],
      stdio: 'inherit'
      env: Object.assign {}, env, process.env

startProduction = ->
  logger.log 'Starting production server...'

  validate paths.entryPoint, 'Entry point'

  spawn getCoffeePath(), [paths.entryPoint],
    stdio: 'inherit'
    env: Object.assign {},
      process.env
      NODE_ENV: 'production'

module.exports = {
  startDev
  startProduction
}
