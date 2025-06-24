module.exports = (req, res) ->
  {repo} = req.params
  browsePath = req.query.path or ''
  browseData = require('./lib/apis').browseRepository(repo, browsePath)
  app.formatResponse req, res, browseData
