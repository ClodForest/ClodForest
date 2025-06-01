# Spirograph Playground

Parametric function playground with adaptive sampling, now fully converted to CoffeeScript!

## Features

- **Adaptive Sampling**: Intelligent step sizing based on function-space distance
- **Backtracking Algorithm**: Finds optimal step sizes for smooth curves
- **Curvature Estimation**: Adjusts sampling density in high-curvature regions
- **Real-time Compilation**: Auto-compile with 3-second delay
- **Preset Library**: Rose curves, Lissajous figures, spirals, and more
- **Debug Mode**: Visualize step sizes and sampling behavior

## Quick Start

```bash
# Install dependencies
npm install

# Start the server
npm start

# Open browser to http://localhost:3000
```

## Architecture

**Modular CoffeeScript Design:**
- `config.coffee` - Configuration objects
- `state.coffee` - Centralized state management
- `compiler.coffee` - Function compilation utilities
- `sampler-utils.coffee` - Geometry and scaling utilities
- `sampler.coffee` - Adaptive sampling algorithms
- `renderer.coffee` - Canvas rendering functions
- `ui.coffee` - UI interaction handlers
- `presets.coffee` - Preset configurations
- `main.coffee` - Initialization

## Usage

1. Write position functions that return `{x, y}` coordinates
2. Write color functions that return `{r, g, b, a}` values
3. Functions auto-compile after 3 seconds or on blur
4. Use presets for inspiration
5. Debug mode shows step size visualization

## Technical Notes

- Uses browser CoffeeScript compiler for development
- Adaptive sampling targets 1.0/scale function-space distance
- Backtracking finds optimal step sizes within 3 attempts
- Maximum 50,000 samples for performance
- CORS-safe with Express server wrapper

## Why CoffeeScript?

As is tradition, CoffeeScript provides:
- Cleaner syntax with significant whitespace
- Implicit returns and comprehensions
- Better function composition patterns
- Reduced boilerplate for object-oriented patterns
