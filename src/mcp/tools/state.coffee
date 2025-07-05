# FILENAME: { ClodForest/src/mcp/tools/state.coffee }
# State directory access tools

fs   = require 'node:fs/promises'
path = require 'node:path'

# Base state directory
STATE_DIR = path.join process.cwd(), 'state'

# Validate and sanitize file paths to prevent directory traversal
validatePath = (filePath) ->
  unless filePath and typeof filePath is 'string'
    throw new Error 'Path must be a non-empty string'

  # Remove leading slashes and normalize
  normalizedPath = path.normalize filePath.replace(/^\/+/, '')
  
  # Check for directory traversal attempts
  if normalizedPath.includes('..') or normalizedPath.startsWith('/')
    throw new Error 'Invalid path: directory traversal not allowed'

  # Resolve full path and ensure it's within state directory
  fullPath = path.resolve STATE_DIR, normalizedPath
  stateDir = path.resolve STATE_DIR
  
  unless fullPath.startsWith(stateDir + path.sep) or fullPath is stateDir
    throw new Error 'Invalid path: must be within state directory'

  { normalizedPath, fullPath }

# Ensure state directory exists
ensureStateDir = ->
  try
    await fs.mkdir STATE_DIR, recursive: true
  catch error
    unless error.code is 'EEXIST'
      throw new Error "Failed to create state directory: #{error.message}"

# Read a file from the state directory
readStateFile = (filePath) ->
  try
    { fullPath } = validatePath filePath
    
    # Check if file exists and is readable
    await fs.access fullPath, fs.constants.R_OK
    
    # Read file content
    content = await fs.readFile fullPath, 'utf8'
    
    content: [
      type: 'text'
      text: content
    ]

  catch error
    switch error.code
      when 'ENOENT'
        throw new Error "File not found: #{filePath}"
      when 'EACCES'
        throw new Error "Permission denied: #{filePath}"
      when 'EISDIR'
        throw new Error "Path is a directory, not a file: #{filePath}"
      else
        throw new Error "Failed to read file: #{error.message}"

# Write a file to the state directory
writeStateFile = (filePath, content) ->
  try
    unless typeof content is 'string'
      throw new Error 'Content must be a string'

    { fullPath } = validatePath filePath
    
    # Ensure state directory exists
    await ensureStateDir()
    
    # Ensure parent directory exists
    parentDir = path.dirname fullPath
    await fs.mkdir parentDir, recursive: true
    
    # Write file content
    await fs.writeFile fullPath, content, 'utf8'
    
    content: [
      type: 'text'
      text: "Successfully wrote #{content.length} characters to #{filePath}"
    ]

  catch error
    switch error.code
      when 'EACCES'
        throw new Error "Permission denied: #{filePath}"
      when 'ENOSPC'
        throw new Error "No space left on device: #{filePath}"
      else
        throw new Error "Failed to write file: #{error.message}"

# List files and directories in the state directory
listStateFiles = (dirPath = '.') ->
  try
    { fullPath } = validatePath dirPath
    
    # Check if directory exists and is readable
    await fs.access fullPath, fs.constants.R_OK
    
    # Check if it's actually a directory
    stats = await fs.stat fullPath
    unless stats.isDirectory()
      throw new Error "Path is not a directory: #{dirPath}"
    
    # Read directory contents
    entries = await fs.readdir fullPath, withFileTypes: true
    
    # Format entries with type information
    formattedEntries = await Promise.all(
      entries.map (entry) ->
        entryPath = path.join fullPath, entry.name
        stats     = await fs.stat entryPath
        
        name:     entry.name
        type:     if entry.isDirectory() then 'directory' else 'file'
        size:     if entry.isFile() then stats.size else undefined
        modified: stats.mtime.toISOString()
        path:     path.join(dirPath, entry.name).replace(/\\/g, '/')
    )
    
    # Sort entries: directories first, then files, both alphabetically
    formattedEntries.sort (a, b) ->
      if a.type isnt b.type
        return if a.type is 'directory' then -1 else 1
      a.name.localeCompare b.name
    
    listingText = if formattedEntries.length is 0
      "Directory #{dirPath} is empty"
    else
      "Contents of #{dirPath}:\n\n" + 
      formattedEntries.map((entry) ->
        typeIcon = if entry.type is 'directory' then '📁' else '📄'
        sizeInfo = if entry.size? then " (#{entry.size} bytes)" else ''
        "#{typeIcon} #{entry.name}#{sizeInfo}"
      ).join('\n')
    
    content: [
      type: 'text'
      text: listingText
    ]

  catch error
    switch error.code
      when 'ENOENT'
        throw new Error "Directory not found: #{dirPath}"
      when 'EACCES'
        throw new Error "Permission denied: #{dirPath}"
      when 'ENOTDIR'
        throw new Error "Path is not a directory: #{dirPath}"
      else
        throw new Error "Failed to list directory: #{error.message}"

module.exports = {
  readStateFile
  writeStateFile
  listStateFiles
}
