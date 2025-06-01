# Sampling algorithms
adaptiveStepCalculator = (currentStep, distance, targetDistance, config) ->
  ratio = distance / targetDistance
  if ratio > 2.0
    # Too far - need smaller step
    currentStep / ratio
  else if ratio < 0.5
    # Too close - can use larger step
    currentStep * 1.5
  else
    currentStep

backtrackingNextPointFinder = (t, currentPos, currentStep, positionFunc, config) ->
  { MAX_ADAPTION_ATTEMPTS, MIN_STEP, MAX_STEP } = config
  targetFunctionDistance = 1.0 / getCanvasScale() # Adaptive to zoom

  step = currentStep
  bestStep = step
  bestDistance = Infinity
  bestPos = null

  # Try to find optimal step size
  for attempt in [0...MAX_ADAPTION_ATTEMPTS]
    newT = Math.min t + step, 1.0
    newPos = positionFunc newT, AppState.getMathContext()
    distance = calculateFunctionSpaceDistance currentPos, newPos
    error = Math.abs distance - targetFunctionDistance

    if error < bestDistance
      bestDistance = error
      bestStep = step
      bestPos = newPos

    # Adjust step based on how far off we are
    step = adaptiveStepCalculator step, distance, targetFunctionDistance, config
    step = Math.max MIN_STEP, Math.min MAX_STEP, step

    # Good enough?
    break if error < targetFunctionDistance * 0.1

  finalT = Math.min t + bestStep, 1.0
  t: finalT
  step: bestStep
  pos: bestPos or positionFunc finalT, AppState.getMathContext()

adaptiveSampler = (positionFunc, nextPointFinder = backtrackingNextPointFinder) ->
  throw new Error 'Position function is required' unless typeof positionFunc is 'function'

  step = samplerConfig.MAX_STEP
  sampleCount = 0

  currentPos = positionFunc 0, AppState.getMathContext()
  yield { t: 0, location: currentPos }
  sampleCount++

  # Track recent points for curvature estimation
  prevPos = null
  t = 0

  while t < 1.0 and sampleCount < canvasConfig.MAX_SAMPLES
    result = nextPointFinder t, currentPos, step, positionFunc, samplerConfig

    # Estimate curvature to adjust step more intelligently
    if prevPos and result.pos
      curvature = estimateCurvature prevPos, currentPos, result.pos
      if curvature > 0.1
        # High curvature area - reduce max step temporarily
        step = Math.min step, samplerConfig.MAX_STEP / 2

    t = result.t
    step = result.step
    prevPos = currentPos
    currentPos = result.pos

    yield { t, location: currentPos }
    sampleCount++

    break if t >= 1.0

fixedStepSampler = (positionFunc, steps = 1000) ->
  ->
    for i in [0..steps]
      t = i / steps
      location = positionFunc t, AppState.getMathContext()
      yield { t, location }

# Export for browser
if typeof window isnt 'undefined'
  window.adaptiveStepCalculator = adaptiveStepCalculator
  window.backtrackingNextPointFinder = backtrackingNextPointFinder
  window.adaptiveSampler = adaptiveSampler
  window.fixedStepSampler = fixedStepSampler
