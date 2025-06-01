# Rendering functions

# Fourth normal form color conversion
colorToRgba = (color, alpha = 0.8) ->
  clamp = (value) -> Math.max 0, Math.min 1, value or 0
  scale = (value) -> Math.floor 255 * clamp value

  [r, g, b] = [color.r, color.g, color.b].map scale
  a = clamp color.a or 1

  "rgba(#{r}, #{g}, #{b}, #{a * alpha})"

# Centralized DOM access
theWorld = ->
  status = document.getElementById 'status'
  canvas = document.getElementById 'spiralCanvas'
  ctx    = canvas  .getContext     '2d'
  
  { status, canvas, ctx }

# Sample generation
samplePoints = (canvas, canvasCenter) ->
  points = []
  
  for sample from adaptiveSampler AppState.getPositionFunc()
    canvasCoords = scaleToCanvas canvas, sample.location, canvasCenter
    color = AppState.getColorFunc() sample.t, AppState.getMathContext()
    
    points.push { canvas: canvasCoords, color: color, t: sample.t }
  
  points

# Rendering primitives
drawDots = (ctx, points) ->
  for point in points
    ctx.save()
    ctx.fillStyle = colorToRgba point.color
    ctx.beginPath()
    ctx.arc point.canvas.x, point.canvas.y, 2, 0, 2 * Math.PI
    ctx.fill()
    ctx.restore()

drawDebugDots = (ctx, points, stepSizes) ->
  [maxStep, minStep] = [Math.max(stepSizes...), Math.min(stepSizes...)]
  
  for point in points
    normalizedStep = if maxStep > minStep 
      (point.stepSize - minStep) / (maxStep - minStep) 
    else 
      0
    
    dotSize = 2 + (1 - normalizedStep) * 3

    ctx.save()
    ctx.fillStyle = colorToRgba point.color, 0.9
    ctx.beginPath()
    ctx.arc point.canvas.x, point.canvas.y, dotSize, 0, 2 * Math.PI
    ctx.fill()
    ctx.restore()

# Status management
updateStatus = (message, color = "#4f4") ->
  { status } = theWorld()
  
  status.textContent = message
  status.style.color = color

# Debug sampler (extracted for reuse)
createDebugSampler = ->
  t = 0
  step = samplerConfig.MAX_STEP
  sampleCount = 0

  currentPos = AppState.getPositionFunc() 0, AppState.getMathContext()
  yield { t: 0, location: currentPos, stepSize: step }
  sampleCount++

  while t < 1.0 and sampleCount < canvasConfig.MAX_SAMPLES
    result = backtrackingNextPointFinder t, currentPos, step, AppState.getPositionFunc(), samplerConfig

    t = result.t
    step = result.step
    currentPos = result.pos

    yield { t, location: currentPos, stepSize: step }
    sampleCount++

    break if t >= 1.0

# Main rendering functions
renderCurrent = ->
  { canvas, ctx } = theWorld()

  unless AppState.hasValidFunctions()
    updateStatus "❌ No functions compiled yet", "#f44"
    return

  ctx.clearRect 0, 0, canvas.width, canvas.height

  try
    canvasCenter = getCanvasCenter()
    points = samplePoints canvas, canvasCenter
    
    drawDots ctx, points if points.length > 0
    updateStatus "✨ Rendered #{points.length} adaptive samples"

  catch error
    errorMsg = error.message.replace /^.*?: /, ''
    updateStatus "❌ Runtime error: #{errorMsg}", "#f44"

clearCanvas = ->
  { status, canvas, ctx } = theWorld()
    
  ctx.clearRect 0, 0, canvas.width, canvas.height
  status.textContent = "Canvas cleared."
  status.style.color = "#fff"

renderWithDebugInfo = ->
  { canvas, ctx } = theWorld()

  return unless AppState.hasValidFunctions()

  ctx.clearRect 0, 0, canvas.width, canvas.height
  canvasCenter = getCanvasCenter()
  debugData = []

  # Collect debug data
  for sample from createDebugSampler()
    canvasCoords = scaleToCanvas canvas, sample.location, canvasCenter
    color = AppState.getColorFunc() sample.t, AppState.getMathContext()
    
    debugData.push
      canvas: canvasCoords
      color: color
      t: sample.t
      stepSize: sample.stepSize

  # Render with debug visualization
  stepSizes = debugData.map (d) -> d.stepSize
  drawDebugDots ctx, debugData, stepSizes

  [minStep, maxStep] = [Math.min(stepSizes...), Math.max(stepSizes...)]
  updateStatus "🔍 Debug: #{debugData.length} samples, step range: #{minStep.toExponential(2)} - #{maxStep.toExponential(2)}"

renderWithSampler = (samplerFunc) ->
  { canvas, ctx } = theWorld()

  return unless AppState.hasValidFunctions()

  ctx.clearRect 0, 0, canvas.width, canvas.height
  canvasCenter = getCanvasCenter()
  points = []

  for sample from samplerFunc()
    canvasCoords = scaleToCanvas canvas, sample.location, canvasCenter
    color = AppState.getColorFunc() sample.t, AppState.getMathContext()
    points.push { canvas: canvasCoords, color: color, t: sample.t }

  drawDots ctx, points if points.length > 0
  updateStatus "✨ Rendered #{points.length} samples"

# Export for browser
if typeof window isnt 'undefined'
  window.renderCurrent = renderCurrent
  window.clearCanvas = clearCanvas
  window.renderWithDebugInfo = renderWithDebugInfo
  window.renderWithSampler = renderWithSampler
