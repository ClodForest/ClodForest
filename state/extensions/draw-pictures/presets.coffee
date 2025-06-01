# Preset configurations
# Note: In production, these would be loaded from presets.yaml
# For now, keeping them inline for js2coffee compatibility

presetTemplates = {}

# This will be populated either by loading presets.yaml or 
# by inline initialization below
initializePresets = ->
  # Check if we can load from YAML
  if typeof loadPresetsFromYAML is 'function'
    loadPresetsFromYAML()
  else
    # Fallback inline presets
    presetTemplates.original =
      position: """
        const tRadians = t * 2 * PI;
        return {
          x: sin(tRadians) * 2,
          y: cos(tRadians) * 3
        };
        """
      color: """
        const oneThirdCircle = (whichThird) => (Tau / 3) * whichThird;
        return {
          r: colorClamp(sin(t + oneThirdCircle(0))),
          g: colorClamp(sin(t + oneThirdCircle(1))),
          b: colorClamp(sin(t + oneThirdCircle(2))),
          a: 1
        };
        """
    
    presetTemplates.spiral =
      position: """
        const angle = t * 8 * PI;
        const radius = t;
        return {
          x: cos(angle) * radius,
          y: sin(angle) * radius
        };
        """
      color: """
        return {
          r: t,
          g: 1 - t,
          b: sin(t * PI) * 0.5 + 0.5,
          a: 1
        };
        """
    
    presetTemplates.lissajous =
      position: """
        return {
          x: sin(t * 3 * PI),
          y: sin(t * 2 * PI)
        };
        """
      color: """
        return {
          r: (sin(t * 4 * PI) + 1) * 0.5,
          g: (cos(t * 6 * PI) + 1) * 0.5,
          b: (sin(t * 8 * PI + PI/2) + 1) * 0.5,
          a: 1
        };
        """
    
    presetTemplates.rose =
      position: """
        const k = 5;
        const angle = t * 2 * PI;
        const r = sin(k * angle);
        return {
          x: r * cos(angle),
          y: r * sin(angle)
        };
        """
      color: """
        const hue = t * 6;
        return {
          r: (sin(hue) + 1) * 0.5,
          g: (sin(hue + 2) + 1) * 0.5,
          b: (sin(hue + 4) + 1) * 0.5,
          a: 1
        };
        """

getPreset = (name) ->
  throw new Error "Preset '#{name}' not found" unless presetTemplates[name]
  presetTemplates[name]

loadPreset = (name) ->
  try
    preset = getPreset name
    positionEditor.value = preset.position
    colorEditor.value = preset.color
    renderCurrent() if compileUserFunctions()
  catch error
    console.warn "Failed to load preset: #{error.message}"

# Export for browser
if typeof window isnt 'undefined'
  window.presetTemplates = presetTemplates
  window.initializePresets = initializePresets
  window.getPreset = getPreset
  window.loadPreset = loadPreset

# Initialize presets on load
initializePresets()
