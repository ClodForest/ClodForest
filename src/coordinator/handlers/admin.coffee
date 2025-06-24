module.exports = (req, res) ->
  if config.FEATURES.ADMIN_AUTH and config.isProduction
    return res.status(401).json error: 'Authentication required'
  html = require('./lib/apis').generateAdminHTML()
  res.send html
