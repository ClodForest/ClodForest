module.exports = (req, res) ->
  healthData = require('./lib/apis').getHealthData()
  app.formatResponse req, res, healthData
