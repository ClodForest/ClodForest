# ClodForest Test Suite
# Main test runner using bevry/kava framework

kava = require 'kava'

# Import all test suites
require './config.test'
require './routing.test'
require './apis.test'
require './integration.test'

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
      app = require '../src/coordinator/index'
      if app.app and app.server
        done()
      else
        done(new Error('App or server not properly exported'))
    catch error
      done(error)
