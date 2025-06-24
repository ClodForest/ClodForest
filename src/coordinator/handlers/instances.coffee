module.exports = (req, res) ->
  instanceData = require('./lib/apis').getInstancesData()
  app.formatResponse req, res, instanceData
