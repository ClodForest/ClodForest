# Simple Express server for CoffeeScript development
express = require 'express'
path = require 'path'

app = express()
PORT = 3000

# Serve static files from current directory
app.use express.static __dirname

# Default route serves index.html
app.get '/', (req, res) ->
  res.sendFile path.join __dirname, 'index.html'

app.listen PORT, ->
  console.log "🌈 Spirograph playground running at http://localhost:#{PORT}"
  console.log 'Press Ctrl+C to stop'
