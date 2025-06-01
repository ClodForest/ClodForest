# Rendering functions
renderCurrent = ->
  status = document.getElementById 'status'
  canvas = document.getElementById 'spiralCanvas'
  ctx = canvas.getContext '2d'

  unless AppState.hasValidFunctions()
    status.textContent = "❌ No functions compiled yet"
    status.style.color = "#f44"
    return

  ctx.clearRect 0, 0, canvas.width, canvas.height

  try
    ctx.strokeStyle = 'rgba(255,255,255,0.3)'
    ctx.lineWidth = 1

    canvasCenter = getCanvasCenter()
    points = []

    for sample from adaptiveSampler AppState.getPositionFunc()
      canvasCoords = scaleToCanvas canvas, sample.location, canvasCenter
      color = AppState.getColorFunc() sample.t, AppState.getMathContext()
      points.push { canvas: canvasCoords, color: color, t: sample.t }

    if points.length > 0
      # Draw path
      ctx.beginPath()
      ctx.moveTo points[0].canvas.x, points[0].canvas.y
      for i in [1...points.length]
        ctx.lineTo points[i].canvas.x, points[i].canvas.y
      ctx.stroke()

      # Draw dots
      for point in points
        ctx.save()
        r = Math.floor Math.max 0, Math.min 1, point.color.r * 255
        g = Math.floor Math.max 0, Math.min 1, point.color.g * 255
        b = Math.floor Math.max 0, Math.min 1, point.color.b * 255
        a = Math.max 0, Math.min 1, point.color.a or 1
        ctx.fillStyle = "rgba(#{r}, #{g}, #{b}, #{a * 0.8})"
        ctx.beginPath()
        ctx.arc point.canvas.x, point.canvas.y, 2, 0, 2 * Math.PI
        ctx.fill()
        ctx.restore()

    status.textContent = "✨ Rendered #{points.length} adaptive samples"
    status.style.color = "#4f4"

  catch error
    errorMsg = error.message.replace /^.*?: /, ''
    status.textContent = "❌ Runtime error: #{errorMsg}"
    status.style.color = "#f44"

clearCanvas = ->
  status = document.getElementById 'status'
  canvas = document.getElementById 'spiralCanvas'
  ctx = canvas.getContext '2d'
  ctx.clearRect 0, 0, canvas.width, canvas.height
  status.textContent = "Canvas cleared."
  status.style.color = "#fff"

renderWithDebugInfo = ->
  status = document.getElementById 'status'
  canvas = document.getElementById 'spiralCanvas'
  ctx = canvas.getContext '2d'

  return unless AppState.hasValidFunctions()

  ctx.clearRect 0, 0, canvas.width, canvas.height

  canvasCenter = getCanvasCenter()
  debugData = []

  # Create debug version of adaptive sampler
  debugAdaptiveSampler = ->
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

  # Collect debug data
  for sample from debugAdaptiveSampler()
    canvasCoords = scaleToCanvas canvas, sample.location, canvasCenter
    color = AppState.getColorFunc() sample.t, AppState.getMathContext()
    debugData.push
      canvas: canvasCoords
      color: color
      t: sample.t
      stepSize: sample.stepSize

  # Calculate step size range
  stepSizes = debugData.map (d) -> d.stepSize
  maxStep = Math.max stepSizes...
  minStep = Math.min stepSizes...

  # Draw dots with size based on step size
  for point in debugData
    normalizedStep = if maxStep > minStep then (point.stepSize - minStep) / (maxStep - minStep) else 0
    dotSize = 2 + (1 - normalizedStep) * 3

    ctx.save()
    r = Math.floor Math.max 0, Math.min 1, point.color.r * 255
    g = Math.floor Math.max 0, Math.min 1, point.color.g * 255
    b = Math.floor Math.max 0, Math.min 1, point.color.b * 255
    ctx.fillStyle = "rgba(#{r}, #{g}, #{b}, 0.9)"
    ctx.beginPath()
    ctx.arc point.canvas.x, point.canvas.y, dotSize, 0, 2 * Math.PI
    ctx.fill()
    ctx.restore()

  status.textContent = "🔍 Debug: #{debugData.length} samples, " +
    "step range: #{minStep.toExponential(2)} - #{maxStep.toExponential(2)}"
  status.style.color = "#4f4"

renderWithSampler = (samplerFunc) ->
  status = document.getElementById 'status'
  canvas = document.getElementById 'spiralCanvas'
  ctx = canvas.getContext '2d'

  return unless AppState.hasValidFunctions()

  ctx.clearRect 0, 0, canvas.width, canvas.height
  ctx.strokeStyle = 'rgba(255,255,255,0.3)'
  ctx.lineWidth = 1

  canvasCenter = getCanvasCenter()
  points = []

  for sample from samplerFunc()
    canvasCoords = scaleToCanvas canvas, sample.location, canvasCenter
    color = AppState.getColorFunc() sample.t, AppState.getMathContext()
    points.push { canvas: canvasCoords, color: color, t: sample.t }

  if points.length > 0
    # Draw path
    ctx.beginPath()
    ctx.moveTo points[0].canvas.x, points[0].canvas.y
    for i in [1...points.length]
      ctx.lineTo points[i].canvas.x, points[i].canvas.y
    ctx.stroke()

    # Draw dots
    for point in points
      ctx.save()
      r = Math.floor Math.max 0, Math.min 1, point.color.r * 255
      g = Math.floor Math.max 0, Math.min 1, point.color.g * 255
      b = Math.floor Math.max 0, Math.min 1, point.color.b * 255
      a = Math.max 0, Math.min 1, point.color.a or 1
      ctx.fillStyle = "rgba(#{r}, #{g}, #{b}, #{a * 0.8})"
      ctx.beginPath()
      ctx.arc point.canvas.x, point.canvas.y, 2, 0, 2 * Math.PI
      ctx.fill()
      ctx.restore()

  status.textContent = "✨ Rendered #{points.length} samples"
  status.style.color = "#4f4"

# Export for browser
if typeof window isnt 'undefined'
  window.renderCurrent = renderCurrent
  window.clearCanvas = clearCanvas
  window.renderWithDebugInfo = renderWithDebugInfo
  window.renderWithSampler = renderWithSampler
