# FILENAME: { ClodForest/src/lib/version.coffee }
# Version management with auto-incrementing build number

fs = require 'node:fs/promises'
path = require 'node:path'

# Version file path
VERSION_FILE = path.join process.cwd(), 'version.json'

# Load or create version info
loadVersion = ->
  try
    data = await fs.readFile VERSION_FILE, 'utf8'
    JSON.parse data
  catch
    # Create initial version if file doesn't exist
    initialVersion = 
      major: 1
      minor: 0
      patch: 0
      build: 0
      lastBuild: new Date().toISOString()
    
    await fs.writeFile VERSION_FILE, JSON.stringify(initialVersion, null, 2)
    initialVersion

# Increment build number on startup
incrementBuild = ->
  version = await loadVersion()
  version.build += 1
  version.lastBuild = new Date().toISOString()
  
  await fs.writeFile VERSION_FILE, JSON.stringify(version, null, 2)
  version

# Get current version info
getVersion = ->
  version = await incrementBuild()
  
  {
    version: "#{version.major}.#{version.minor}.#{version.patch}"
    build: version.build
    full: "#{version.major}.#{version.minor}.#{version.patch}-build.#{version.build}"
    lastBuild: version.lastBuild
    nodeVersion: process.version
    environment: process.env.NODE_ENV or 'development'
  }

module.exports = { getVersion }