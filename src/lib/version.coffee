# FILENAME: { ClodForest/src/lib/version.coffee }
# Version management using git commit info

{ execSync } = require 'node:child_process'
fs = require 'node:fs/promises'
path = require 'node:path'

# Get git commit info
getGitInfo = ->
  try
    commit = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim()
    shortCommit = commit.substring(0, 8)
    commitCount = parseInt(execSync('git rev-list --count HEAD', { encoding: 'utf8' }).trim())
    branch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8' }).trim()
    
    {
      commit: commit
      shortCommit: shortCommit
      commitCount: commitCount
      branch: branch
    }
  catch
    # Fallback if not in git repo
    {
      commit: 'unknown'
      shortCommit: 'unknown'
      commitCount: 0
      branch: 'unknown'
    }

# Get current version info
getVersion = ->
  git = getGitInfo()
  
  {
    version: "1.0.0"
    build: git.commitCount
    commit: git.shortCommit
    branch: git.branch
    full: "1.0.0-#{git.commitCount}-#{git.shortCommit}"
    nodeVersion: process.version
    environment: process.env.NODE_ENV or 'development'
    deployedAt: new Date().toISOString()
  }

module.exports = { getVersion }