module.exports = (req, res) ->
  {trash} = req.params
  cacheBustingData =
    busted: true
    originalPath: req.params[0]
    timestamp: new Date().toISOString()
    message: "Busted dat cache"
  app.formatResponse req, res, cacheBustingData
