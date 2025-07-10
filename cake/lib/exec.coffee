# FILENAME: { ClodForest/cake/lib/exec.coffee }
# Async command execution utilities

{exec, spawn} = require 'child_process'
{promisify} = require 'util'
logger = require './logger'

execAsync = promisify exec

run = (command, options = {}) ->
  logger.debug "Running: #{command}"
  
  try
    {stdout, stderr} = await execAsync command, options
    console.log stdout if stdout and not options.silent
    stdout
  catch err
    logger.error "Command failed: #{command}"
    console.error err.stderr if err.stderr
    throw err

runOrFail = (command, options = {}) ->
  try
    await run command, options
  catch err
    process.exit 1

spawnAsync = (command, args = [], options = {}) ->
  new Promise (resolve, reject) ->
    child = spawn command, args, options
    
    child.on 'close', (code) ->
      if code is 0
        resolve code
      else
        reject new Error "Process exited with code #{code}"
        
    child.on 'error', reject

module.exports = {
  run
  runOrFail
  spawn: spawnAsync
}