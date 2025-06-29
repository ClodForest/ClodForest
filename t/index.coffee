# ClodForest Test Suite
# Main test runner using bevry/kava framework

kava = require 'kava'

# Import all test suites
require './config.test'
require './routing.test'
require './apis.test'
require './integration.test'
require './mcp.test'

# Run the test suite
kava.suite 'ClodForest Coordinator', (suite, test) ->
  
  test 'should have all required dependencies', (done) ->
    try
      require 'express'
      require 'cors'
      require 'js-yaml'
      done()
    catch error
      done(error)

  test 'should load main application module', (done) ->
    try
      coordinator = require '../src/coordinator/index'
      if coordinator.app and coordinator.server and coordinator.startServer
        done()
      else
        done(new Error('App, server, or startServer not properly exported'))
    catch error
      done(error)
