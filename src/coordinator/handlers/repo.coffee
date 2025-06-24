module.exports = (req, res) ->
  repoData = require('./lib/apis').getRepositoryData()
  app.formatResponse req, res, repoData
