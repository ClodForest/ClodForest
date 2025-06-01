# Optional YAML loader for presets
# This file can be included if you want to load presets from YAML
# Requires a YAML parser library like js-yaml

loadPresetsFromYAML = ->
  # This would typically use fetch() to load presets.yaml
  # and a YAML parser to convert it to JavaScript objects
  # For now, this is a placeholder
  
  # Example implementation (requires js-yaml):
  ###
  fetch('presets.yaml')
    .then (response) -> response.text()
    .then (yamlText) ->
      parsed = jsyaml.load yamlText
      Object.assign presetTemplates, parsed
    .catch (error) ->
      console.warn 'Failed to load presets.yaml, using inline presets'
  ###

# Export for browser
if typeof window isnt 'undefined'
  window.loadPresetsFromYAML = loadPresetsFromYAML
