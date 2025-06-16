#!/usr/bin/env coffee

fs   = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

CONFIG = ->
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

fileExists = (filePath) ->
  try
    fs.statSync(filePath).isFile()
  catch
    false

parseYamlFile = (filePath) ->
  try
    content = fs.readFileSync filePath, 'utf8'
    yaml.load content
  catch
    null

analyzeFileComments = (filePath) ->
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

validateFileExtension = (filePath) ->
  ext = path.extname filePath
  CONFIG().VALID_EXTENSIONS.includes ext

checkYamlExtension = (filePath) ->
  ext = path.extname filePath
  CONFIG().YAML_EXTENSIONS.includes ext

checkInContextsDirectory = (filePath) ->
  filePath.includes CONFIG().CONTEXT_DIR

detectYamlLikeContent = (filePath) ->
  try
    content = fs.readFileSync filePath, 'utf8'
    content.match(/^\s*\w+\s*:\s*/m) isnt null
  catch
    false

addFileToState = (filePath, baseDir, state) ->
  relativePath = path.relative baseDir, filePath
  state.allFiles.add relativePath

scanDirectoryRecursively = (dir, baseDir, state) ->
  try
    items = fs.readdirSync dir
    for item in items
      fullPath = path.join dir, item
      
      if fs.statSync(fullPath).isDirectory()
        scanDirectoryRecursively fullPath, baseDir, state
      else
        addFileToState fullPath, baseDir, state
  catch error
    state.errors.push "Failed to scan directory #{dir}: #{error.message}"

scanAllFiles = (state) ->
  config = CONFIG()
  scanDirectoryRecursively config.STATE_DIR, config.STATE_DIR, state
  state

extractPathsFromData = (obj, key) ->
  return [] unless obj?[key]
  if Array.isArray obj[key]
    obj[key]
  else
    [obj[key]]

processReferencePaths = (paths, processFile) ->
  for referencePath in paths when referencePath
    processFile referencePath

processFileReferences = (filePath, visited, state) ->
  config = CONFIG()
  return if visited.has filePath
  visited.add filePath
  state.reachableFiles.add filePath
  
  fullPath = path.join config.STATE_DIR, filePath
  return unless fileExists fullPath
  
  data = parseYamlFile fullPath
  return unless data
  
  if data.inherits
    paths = extractPathsFromData data, 'inherits'
    processReferencePaths paths, (path) -> processFileReferences path, visited, state
  
  if data.references
    paths = extractPathsFromData data, 'references'
    processReferencePaths paths, (path) -> processFileReferences path, visited, state
  
  if data.auto_load
    paths = extractPathsFromData data, 'auto_load'
    processReferencePaths paths, (path) -> processFileReferences path, visited, state

followAllReferences = (state) ->
  visited = new Set()
  config = CONFIG()
  processFileReferences config.BOOTSTRAP_FILE, visited, state
  state

validateYamlFileComments = (filePath, state) ->
  config = CONFIG()
  fullPath = path.join config.STATE_DIR, filePath
  commentAnalysis = analyzeFileComments fullPath
  if commentAnalysis.hasComments
    state.errors.push "YAML file contains comments: #{filePath} (#{commentAnalysis.commentCount} comment lines)"

validateFileExtensions = (filePath, state) ->
  unless validateFileExtension filePath
    state.warnings.push "File has non-standard extension: #{filePath}"

validateMarkdownInContexts = (filePath, state) ->
  config = CONFIG()
  if path.extname(filePath) is '.md' and checkInContextsDirectory filePath
    fullPath = path.join config.STATE_DIR, filePath
    if detectYamlLikeContent fullPath
      state.warnings.push "Markdown file in contexts/ contains YAML-like content: #{filePath}"

validateSingleFile = (filePath, state) ->
  validateFileExtensions filePath, state
  
  if checkYamlExtension filePath
    validateYamlFileComments filePath, state
  
  validateMarkdownInContexts filePath, state

validateAllFormats = (state) ->
  for filePath from state.allFiles
    validateSingleFile filePath, state
  state

calculateOrphanedFiles = (state) ->
  new Set([...state.allFiles].filter (file) -> not state.reachableFiles.has file)

printSummaryStatistics = (state, orphanedFiles) ->
  console.log "State Directory Audit Results"
  console.log "============================="
  console.log "Total files found: #{state.allFiles.size}"
  console.log "Reachable files: #{state.reachableFiles.size}"
  console.log "Orphaned files: #{orphanedFiles.size}"
  console.log "Errors: #{state.errors.length}"
  console.log "Warnings: #{state.warnings.length}"

printOrphanedFiles = (orphanedFiles) ->
  if orphanedFiles.size > 0
    console.log "\nOrphaned Files:"
    for file from orphanedFiles
      console.log "  #{file}"

printErrors = (errors) ->
  if errors.length > 0
    console.log "\nErrors:"
    for error in errors
      console.log "  ERROR: #{error}"

printWarnings = (warnings) ->
  if warnings.length > 0
    console.log "\nWarnings:"
    for warning in warnings
      console.log "  WARNING: #{warning}"

createInitialState = ->
  allFiles       : new Set()
  reachableFiles : new Set()
  errors         : []
  warnings       : []

processAuditResults = (state) ->
  orphanedFiles = calculateOrphanedFiles state
  
  printSummaryStatistics state, orphanedFiles
  printOrphanedFiles orphanedFiles
  printErrors state.errors
  printWarnings state.warnings
  
  if state.errors.length > 0
    process.exit 1
  else
    process.exit 0

main = ->
  if process.argv.includes('-h') or process.argv.includes('--help')
    showHelp()
    process.exit 0
  
  state = createInitialState()
  state = scanAllFiles state
  state = followAllReferences state
  state = validateAllFormats state
  
  processAuditResults state

main()