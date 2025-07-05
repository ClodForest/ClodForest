# FILENAME: { ClodForest/src/middleware/auth.coffee }
# OAuth2 authentication middleware

OAuth2Server = require 'oauth2-server'
OAuth2Model  = require '../oauth/model'

model = new OAuth2Model()

oauth = new OAuth2Server
  model:                        model
  grants:                       ['client_credentials']
  debug:                        process.env.NODE_ENV is 'development'
  accessTokenLifetime:          3600
  allowBearerTokensInQueryString: false
  allowEmptyState:              false

# OAuth2 authentication middleware
authenticate = (req, res, next) ->
  try
    request  = new OAuth2Server.Request req
    response = new OAuth2Server.Response res

    # Authenticate the request
    token = await oauth.authenticate request, response
    
    # Add token info to request object
    req.oauth =
      token:  token
      client: token.client
      scope:  token.scope

    next()

  catch error
    console.error 'Authentication error:', error
    
    # Handle OAuth2 authentication errors
    if error.name is 'UnauthorizedRequestError'
      return res.status(401).json
        error:             'invalid_token'
        error_description: 'The access token provided is expired, revoked, malformed, or invalid'

    if error.name is 'InsufficientScopeError'
      return res.status(403).json
        error:             'insufficient_scope'
        error_description: 'The request requires higher privileges than provided by the access token'

    # Generic authentication error
    res.status(401).json
      error:             'invalid_token'
      error_description: 'Authentication failed'

# Scope verification middleware factory
requireScope = (requiredScope) ->
  (req, res, next) ->
    unless req.oauth?.token
      return res.status(401).json
        error:             'invalid_token'
        error_description: 'No valid token found'

    tokenScopes    = if req.oauth.scope then req.oauth.scope.split(' ') else []
    requiredScopes = requiredScope.split ' '

    hasRequiredScope = requiredScopes.every (scope) -> tokenScopes.includes scope

    unless hasRequiredScope
      return res.status(403).json
        error:             'insufficient_scope'
        error_description: "Required scope: #{requiredScope}"

    next()

module.exports = authenticate
module.exports.requireScope = requireScope
