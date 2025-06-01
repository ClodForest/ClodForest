# Centralized state management
AppState =
  compiledPositionFunc: null
  compiledColorFunc: null
  mathContext:
    sin: Math.sin
    cos: Math.cos
    PI: Math.PI
    Tau: Math.PI * 2
    colorClamp: (x) -> Math.max 0, Math.min 1, x
  
  getPositionFunc: -> @compiledPositionFunc
  
  getColorFunc: -> @compiledColorFunc
  
  getMathContext: -> @mathContext
  
  setFunctions: (positionFunc, colorFunc) ->
    @compiledPositionFunc = positionFunc
    @compiledColorFunc = colorFunc
  
  hasValidFunctions: ->
    @compiledPositionFunc and @compiledColorFunc

# Export for browser
if typeof window isnt 'undefined'
  window.AppState = AppState
