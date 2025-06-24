module.exports = (req, res) ->
  {repo, command} = req.params
  {args = []} = req.body
  require('./lib/apis').executeGitCommand repo, command, args, (gitData) ->
    app.formatResponse req, res, gitData
