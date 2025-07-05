# FILENAME: { ClodForest/src/middleware/security.coffee }
# Security middleware configuration

helmet = require 'helmet'

# Security middleware configuration
securityMiddleware = [
  # Basic security headers
  helmet
    contentSecurityPolicy:
      directives:
        defaultSrc:  ["'self'"]
        scriptSrc:   ["'self'"]
        styleSrc:    ["'self'", "'unsafe-inline'"]
        imgSrc:      ["'self'", "data:", "https:"]
        connectSrc:  ["'self'"]
        fontSrc:     ["'self'"]
        objectSrc:   ["'none'"]
        mediaSrc:    ["'self'"]
        frameSrc:    ["'none'"]
    crossOriginEmbedderPolicy: false # Allow for API usage

  # Custom security headers
  (req, res, next) ->
    # Ensure HTTPS in production
    if process.env.NODE_ENV is 'production' and req.header('x-forwarded-proto') isnt 'https'
      return res.redirect "https://#{req.header('host')}#{req.url}"

    # Additional security headers
    res.setHeader 'X-API-Version', '1.0'
    res.setHeader 'X-Powered-By',  'ClodForest'
    
    next()
]

module.exports = securityMiddleware
