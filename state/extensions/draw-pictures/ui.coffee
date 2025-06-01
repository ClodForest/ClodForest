# UI interaction handlers
positionEditor = document.getElementById 'positionCode'
colorEditor = document.getElementById 'colorCode'
status = document.getElementById 'status'

compileTimeout = null

updateUIState = (success, message) ->
  status.textContent = if success
    "✅ Functions compiled successfully!"
  else
    "❌ Compilation error: #{message}"
  status.style.color = if success then "#4f4" else "#f44"

compileUserFunctions = ->
  try
    posCode = positionEditor.value
    colorCode = colorEditor.value
    
    { positionFunc, colorFunc } = compileFunctions posCode, colorCode, AppState.getMathContext()
    
    AppState.setFunctions positionFunc, colorFunc
    updateUIState true
    true
  catch error
    errorMsg = error.message.replace /^.*?: /, ''
    updateUIState false, errorMsg
    false

scheduleCompile = ->
  clearTimeout compileTimeout
  compileTimeout = setTimeout ->
    renderCurrent() if compileUserFunctions()
  , uiConfig.COMPILE_DELAY

handleEditorBlur = ->
  renderCurrent() if compileUserFunctions()

# Centralized event listener setup
initializeEventListeners = ->
  positionEditor.addEventListener 'input', scheduleCompile
  positionEditor.addEventListener 'blur', handleEditorBlur
  colorEditor.addEventListener 'input', scheduleCompile
  colorEditor.addEventListener 'blur', handleEditorBlur

# Export for browser
if typeof window isnt 'undefined'
  window.updateUIState = updateUIState
  window.compileUserFunctions = compileUserFunctions
  window.scheduleCompile = scheduleCompile
  window.handleEditorBlur = handleEditorBlur
  window.initializeEventListeners = initializeEventListeners
