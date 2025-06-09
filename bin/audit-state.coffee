#!/usr/bin/env coffee

fs   = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

CONFIG =
  STATE_DIR        : './state'
  BOOTSTRAP_FILE   : 'contexts/instructions/bootstrap.yaml'
  VALID_EXTENSIONS : ['.yaml', '.yml', '.md', '.txt', '.json']
  YAML_EXTENSIONS  : ['.yaml', '.yml']
  CONTEXT_DIR      : 'contexts'

showHelp = ->
  console.log """
      audit-state.coffee - State directory audit tool

      Usage: coffee audit-state.coffee [options]

      Options:
        -h, --help    Show this help message

      Audits the state directory structure:
          - Scans all files in state/
          - Follows references from bootstrap.yaml
          - Identifies orphaned files
          - Validates YAML format compliance
          - Reports errors and warnings

      Exit codes:
        0 - Success or warnings only
        1 - Errors found
    """

utils =
  fileExists : (filePath) ->
    try
      fs.statSync(filePath).isFile()
    catch
      false

  parseYaml : (filePath) ->
    try
      content = fs.readFileSync filePath, 'utf8'
      yaml.load content
    catch
      null

  hasComments : (filePath) ->
    try
      content = fs.readFileSync filePath, 'utf8'
      lines = content.split '\n'
      commentLines = lines.filter (line) -> line.trim().match(/^\s*#/)

      hasComments    : commentLines.length > 0
      commentCount   : commentLines.length
      totalLines     : lines.length
      commentLines   : commentLines
    catch
      hasComments    : false
      commentCount   : 0
      totalLines     : 0
      commentLines   : []

  isValidExtension : (filePath) ->
    ext = path.extname filePath
    CONFIG.VALID_EXTENSIONS.includes ext

  isYamlExtension : (filePath) ->
    ext = path.extname filePath
    CONFIG.YAML_EXTENSIONS.includes ext

  isInContextsDir : (filePath) ->
    filePath.includes CONFIG.CONTEXT_DIR

  containsYamlLikeContent : (filePath) ->
    try
      content = fs.readFileSync filePath, 'utf8'
      content.match(/^\s*\w+\s*:\s*/m) isnt null
    catch
      false

operations =
  scanDirectory : (state) ->
    scanRecursive = (dir, baseDir) ->
      try
        items = fs.readdirSync dir
        for item in items
          fullPath = path.join dir, item
          relativePath = path.relative baseDir, fullPath

          if fs.statSync(fullPath).isDirectory()
            scanRecursive fullPath, baseDir
          else
            state.allFiles.add relativePath
      catch error
        state.errors.push "Failed to scan directory #{dir}: #{error.message}"

    scanRecursive CONFIG.STATE_DIR, CONFIG.STATE_DIR
    state

  followReferences : (state) ->
    visited = new Set()

    processFile = (filePath) ->
      return if visited.has filePath
      visited.add filePath
      state.reachableFiles.add filePath

      fullPath = path.join CONFIG.STATE_DIR, filePath
      return unless utils.fileExists fullPath

      data = utils.parseYaml fullPath
      return unless data

      extractPaths = (obj, key) ->
        return [] unless obj?[key]
        if Array.isArray obj[key]
          obj[key]
        else
          [obj[key]]

      processPathList = (paths) ->
        for referencePath in paths when referencePath
          processFile referencePath

      if data.inherits
        processPathList extractPaths data, 'inherits'

      if data.references
        processPathList extractPaths data, 'references'

      if data.auto_load
        processPathList extractPaths data, 'auto_load'

    processFile CONFIG.BOOTSTRAP_FILE
    state

  validateFormats : (state) ->
    for filePath from state.allFiles
      fullPath = path.join CONFIG.STATE_DIR, filePath

      unless utils.isValidExtension filePath
        state.warnings.push "File has non-standard extension: #{filePath}"

      if utils.isYamlExtension filePath
        commentAnalysis = utils.hasComments fullPath
        if commentAnalysis.hasComments
          state.errors.push "YAML file contains comments: #{filePath} (#{commentAnalysis.commentCount} comment lines)"

      if path.extname(filePath) is '.md' and utils.isInContextsDir filePath
        if utils.containsYamlLikeContent fullPath
          state.warnings.push "Markdown file in contexts/ contains YAML-like content: #{filePath}"

    state

main = ->
  if process.argv.includes('-h') or process.argv.includes('--help')
    showHelp()
    process.exit 0

  state =
    allFiles       : new Set()
    reachableFiles : new Set()
    errors         : []
    warnings       : []

  state = operations.scanDirectory state
  state = operations.followReferences state
  state = operations.validateFormats state

  orphanedFiles = new Set([...state.allFiles].filter (file) -> not state.reachableFiles.has file)

  console.log "State Directory Audit Results"
  console.log "============================="
  console.log "Total files found: #{state.allFiles.size}"
  console.log "Reachable files: #{state.reachableFiles.size}"
  console.log "Orphaned files: #{orphanedFiles.size}"
  console.log "Errors: #{state.errors.length}"
  console.log "Warnings: #{state.warnings.length}"

  if orphanedFiles.size > 0
    console.log "\nOrphaned Files:"
    for file from orphanedFiles
      console.log "  #{file}"

  if state.errors.length > 0
    console.log "\nErrors:"
    for error in state.errors
      console.log "  ERROR: #{error}"

  if state.warnings.length > 0
    console.log "\nWarnings:"
    for warning in state.warnings
      console.log "  WARNING: #{warning}"

  if state.errors.length > 0
    process.exit 1
  else
    process.exit 0

main()
