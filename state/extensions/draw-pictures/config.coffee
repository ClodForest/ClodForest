# Configuration objects for the application
uiConfig =
  COMPILE_DELAY: 3000

canvasConfig =
  SCALE: 60
  MAX_SAMPLES: 50000
  PIXEL_DISTANCE_THRESHOLD: 2
  DOT_SIZE_MIN: 2
  DOT_SIZE_MAX: 5

samplerConfig =
  MIN_STEP: 1/10000
  MAX_STEP: 1/50  # Increased for better performance on smooth curves
  MAX_ADAPTION_ATTEMPTS: 3
  TARGET_PIXEL_DISTANCE: 2  # Clearer name than MAX_DISTANCE_EPSILON

# Export for browser
if typeof window isnt 'undefined'
  window.uiConfig = uiConfig
  window.canvasConfig = canvasConfig
  window.samplerConfig = samplerConfig
