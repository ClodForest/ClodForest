module.exports = (req, res) ->
  {repo} = req.params
  filePath = req.params[0]  # Everything after /file/
  fileData = require('./lib/apis').readRepositoryFile(repo, filePath)
  app.formatResponse req, res, fileData
