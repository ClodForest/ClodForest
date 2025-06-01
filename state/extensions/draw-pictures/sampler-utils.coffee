# Sampler utility functions
getCanvasScale = ->
  canvasConfig.SCALE

getCanvasCenter = ->
  canvas = document.getElementById 'spiralCanvas'
  return { x: 200, y: 200 } unless canvas
  { x: canvas.width / 2, y: canvas.height / 2 }

pythagoras = (p1, p2) ->
  dx = p1.x - p2.x
  dy = p1.y - p2.y
  Math.sqrt dx * dx + dy * dy

makeClamper = (min, max) ->
  (n) -> Math.max min, Math.min max, n

calculateStepDistance = (currentPos, newPos, scale) ->
  distance = pythagoras currentPos, newPos
  maxPointDistance = canvasConfig.PIXEL_DISTANCE_THRESHOLD / scale
  Math.abs distance - maxPointDistance

adjustStepSize = (step, distance, clamp) ->
  clamp step / distance

calculateFunctionSpaceDistance = (p1, p2) ->
  pythagoras p1, p2

estimateCurvature = (p1, p2, p3) ->
  Math.abs (p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)

scaleToCanvas = (canvas, location, center = null) ->
  actualCenter = center or getCanvasCenter()
  scale = getCanvasScale()
  
  x: actualCenter.x + location.x * scale
  y: actualCenter.y + location.y * scale

# Export for browser
if typeof window isnt 'undefined'
  window.getCanvasScale = getCanvasScale
  window.getCanvasCenter = getCanvasCenter
  window.pythagoras = pythagoras
  window.makeClamper = makeClamper
  window.calculateStepDistance = calculateStepDistance
  window.adjustStepSize = adjustStepSize
  window.calculateFunctionSpaceDistance = calculateFunctionSpaceDistance
  window.estimateCurvature = estimateCurvature
  window.scaleToCanvas = scaleToCanvas
