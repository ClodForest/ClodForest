# Function compilation utilities
createFunction = (code, contextVars) ->
  varList = contextVars.join ', '
  new Function 't', 'ctx', "const {#{varList}} = ctx;\n#{code}"

validateFunction = (func, context) ->
  func 0, context
  true

compileFunctions = (positionCode, colorCode, mathContext) ->
  positionFunc = createFunction positionCode, ['sin', 'cos', 'PI', 'Tau']
  colorFunc = createFunction colorCode, ['sin', 'cos', 'PI', 'Tau', 'colorClamp']
  
  validateFunction positionFunc, mathContext
  validateFunction colorFunc, mathContext
  
  { positionFunc, colorFunc }

# Export for browser
if typeof window isnt 'undefined'
  window.createFunction = createFunction
  window.validateFunction = validateFunction
  window.compileFunctions = compileFunctions
