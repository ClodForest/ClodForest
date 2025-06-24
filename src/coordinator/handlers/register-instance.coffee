module.exports = (req, res) ->
  require('./lib/apis').registerInstance(req.body)
  res.json status: 'registered', timestamp: new Date().toISOString()
