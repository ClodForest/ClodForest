module.exports.frontPage = (req, res, welcomeData, config) ->
  acceptHTML = req.get('Accept')?.includes 'text/html'

  if not acceptHTML
    app.formatResponse req, res, welcomeData
  else
    res.send """
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{config.SERVICE_NAME}</title>
        <style>
          body { font-family: monospace; margin: 40px; background: #1a1a1a; color: #00ff00; }
          .header { color: #00ffff; font-size: 24px; margin-bottom: 20px; }
          .status { color: #00ff00; }
          .endpoint { color: #ffff00; margin: 5px 0; }
          .feature { color: #ffffff; margin: 3px 0; }
          a { color: #00ffff; }
        </style>
      </head>
      <body>
        <div class="header">🔗 #{config.SERVICE_NAME}</div>
        <div class="status">Status: #{welcomeData.status}</div>
        <div class="status">Version: #{welcomeData.version}</div>
        <br>
        <div>API Endpoints:</div>
        #{
          #<div class="endpoint">• <a href="#{config.API_PATHS.HEALTH}/">#{config.API_PATHS.HEALTH}/</a> - Service health check</div>
          #<div class="endpoint">• <a href="#{config.API_PATHS.TIME}/">#{config.API_PATHS.TIME}/</a> - Time synchronization</div>
          #<div class="endpoint">• <a href="#{config.API_PATHS.REPO}">#{config.API_PATHS.REPO}</a> - Repository listing</div>
          #<div class="endpoint">• <a href="#{config.API_PATHS.ADMIN}">#{config.API_PATHS.ADMIN}</a> - Administrative interface</div>
          for path, handler of config.API_PATHS
            { description = ''
            } = handler
            #{
              """<div class="endpoint">• <a href="#{path}">#{path}</a> - #{description}</div>"""
            #}

          }
        <br>
        <div>Features:</div>
        #{welcomeData.features.map((f) -> "<div class=\"feature\">• #{f}</div>").join('')}
        <br>
        <div>Format: Add <code>Accept: application/json</code> header for JSON, defaults to YAML</div>
      </body>
      </html>
    """

