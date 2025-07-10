# FILENAME: { ClodForest/cake/lib/paths.coffee }
# Path constants and validation

path = require 'path'
fs = require 'fs'

# Project root is two levels up from cake/lib/
PROJECT_ROOT = path.resolve __dirname, '../..'

paths =
  root:        PROJECT_ROOT
  src:         path.join PROJECT_ROOT, 'src'
  entryPoint:  path.join PROJECT_ROOT, 'src/app.coffee'
  config:      path.join PROJECT_ROOT, 'config.yaml'
  state:       path.join PROJECT_ROOT, 'state'
  data:        path.join PROJECT_ROOT, 'data'
  logs:        path.join PROJECT_ROOT, 'logs'
  test:        path.join PROJECT_ROOT, 'test'
  cake:        path.join PROJECT_ROOT, 'cake'
  templates:   path.join PROJECT_ROOT, 'cake/templates'

exists = (filePath) ->
  try
    fs.accessSync filePath, fs.constants.F_OK
    true
  catch
    false

validate = (filePath, description) ->
  unless exists filePath
    throw new Error "#{description} not found: #{filePath}"
  filePath

getCoffeePath = ->
  # Try local node_modules first
  localCoffee = path.join paths.root, 'node_modules/coffeescript/bin/coffee'
  return localCoffee if exists localCoffee
  
  # Fall back to global
  'coffee'

module.exports = {
  paths
  exists
  validate
  getCoffeePath
}