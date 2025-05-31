# Parametric Function Playground

Interactive tool for experimenting with parametric mathematical functions that generate 2D curves with adaptive sampling and real-time compilation.

## Features

- **Live Function Editor**: Edit position and color functions with auto-compilation
- **Adaptive Sampling**: Automatically adjusts sample density based on curve complexity  
- **Mathematical Presets**: Built-in examples (spirals, Lissajous curves, roses)
- **Real-time Rendering**: See changes instantly as you type

## Usage

1. Open `index.html` in a browser
2. Edit the position and color functions in the text areas
3. Functions auto-compile after 3 seconds of typing or when you click away
4. Try the preset buttons for inspiration

## Function Format

**Position Function**: Returns `{x, y}` coordinates in range `[-1, 1]`
**Color Function**: Returns `{r, g, b, a}` values in range `[0, 1]`

Available math: `sin, cos, PI, Tau, colorClamp`

## Architecture

- `ui-component.js`: Function compilation and editor management
- `presets-component.js`: Mathematical function templates  
- `sampler-component.js`: Adaptive sampling algorithm
- `renderer-component.js`: Canvas rendering and coordinate transformation

## Next Steps

- Refactor sampler with dependency injection
- Add CoffeeScript compilation support
- Optimize performance for complex curves
- Add more mathematical functions and constants
