module.exports = (req, res) ->
  timeData = require('./lib/apis').getTimeData(req)
  app.formatResponse req, res, timeData
