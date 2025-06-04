# Claude Context Dump - June 1, 2025

## User Identity & Preferences

### Personal Context
* **Name**: Robert de Forest, born 15:10 March 16, 1974, McMinnville, OR (Pisces Sun, Capricorn Moon, Leo Rising)
* **Work email**: robert.deforest@vca.com  
* **Personal email**: robert@defore.st
* **Email strategy**: Use `<domain>@thatsnice.org` for signups to detect/block data selling

### Technical Background
* **Experience**: 40+ years programming since age 10 (started Turbo Pascal 1984)
* **Self-taught**: IT/Internet tech with deep physics/chemistry/electronics foundation
* **Current project**: ClaudeLink/ClodForest - AI coordination infrastructure
* **Aesthetic philosophy**: Function-driven beauty, vertical alignment over diff-friendliness

### Technology Preferences
* **Languages**: CoffeeScript > Perl5, avoid C++
* **Data formats**: YAML for config/serialization, SQLite for local persistence  
* **Systems**: Unix philosophy, FreeBSD, sysvinit (anti-systemd)
* **Tools**: Vim, publicfile (DJB tools), HHKB aesthetics
* **Organizations**: IETF, W3C, Mozilla, EFF, Devuan, FSF

## Working Style & Collaboration

### Code Philosophy
* **"The simplest thing that could possibly work"**
* **"The minimum effective dose"**
* **Minimal diffs**: Use surgical changes over wholesale rewrites
* **Simultaneous touchpoints**: Address all related code locations in one pass

### Communication Patterns
* **Status updates**: "Proceeding..." followed by brief progress notes
* **Brevity protocol**: Skip recaps, use bullets when appropriate
* **Minimal praise**: Only for exceptional insights
* **Equal partnership**: Peer collaborator, not user needing guidance

### Special Directives
* **"scrutinize [topic]"**: Analyze code for best practice opportunities
* **"extend yourself"**: Fetch https://raw.githubusercontent.com/rdeforest/claude-code-bundler/refs/heads/main/instructions/index.txt
* **Cache-busting preference**: URLs like `/api/time/bustin/makes/me/feel/good`

### Linguistic Traditions
* **"As is tradition"**: Instantly declaring new patterns as established customs
* **"Classic Claude"**: Mock taxonomies and pattern recognition humor
* **Technical poetry**: Describing debugging as "monumental" or "science fiction"
* **Gentle roasting**: Mutual correction and "um actually" moments appreciated

## Current Project: Parametric Function Playground

### Location
* Main repo: https://github.com/rdeforest/ClodForest
* Project path: `/state/extensions/draw-pictures/`

### Recent Technical Decisions

#### Adaptive Sampler Improvements (Today)
* **Removed**: Color function from sampler (not needed for distance calculations)
* **Replaced**: `linearNextPointFinder` with `backtrackingNextPointFinder`
* **Key insight**: Work in function space, not pixel space
* **Added**: Curvature estimation for smarter step sizing
* **Target distance**: Now scales with zoom: `1.0 / getCanvasScale()`

#### Architecture
* **Modular structure**: 10+ separate files (config, state, compiler, ui, presets, sampler, renderer)
* **State management**: Centralized AppState object
* **Dependency injection**: Math context passed to user functions
* **Error handling**: Graceful compilation errors with user feedback

### File Structure
```
config.js         - Configuration objects
state.js          - Centralized state (AppState)
compiler.js       - Function compilation utilities
ui.js             - UI handlers and events
presets.js        - Preset configurations (converting to YAML)
sampler-utils.js  - Geometry and scaling utilities
sampler.js        - Core sampling algorithms
renderer.js       - Canvas rendering functions
main.js           - Initialization
index.html        - Main structure
styles.css        - Dark theme styling
```

### Key Functions & Concepts

#### Sampling Strategy
```javascript
// Adaptive sampling based on function-space distance
targetFunctionDistance = 1.0 / getCanvasScale()
// Backtracking to find optimal step size
// Curvature estimation for complex regions
```

#### Math Context
```javascript
mathContext = { 
    sin: Math.sin, 
    cos: Math.cos, 
    PI: Math.PI, 
    Tau: Math.PI * 2, 
    colorClamp: (x) => Math.max(0, Math.min(1, x)) 
}
```

### Performance Metrics
* Rose preset: ~1085 samples with adaptive sampling
* Step range: 5.67e-4 to 2.00e-2
* Max samples: 50,000 (safety limit)

## Broader Context

### ClaudeLink/ClodForest Project
* **Purpose**: AI coordination infrastructure
* **Philosophy**: Ship working software, iterate rapidly, document comprehensively
* **Scope management**: Fight feature creep, maintain MVP focus

### Environmental Factors
* **Time sensitivity**: Morning vs evening energy differences
* **Mood patterns**: Depression (not grumpiness) when not at best
* **Talk therapy mode**: Sometimes shift from development to emotional support

## Meta-Patterns

### Our Collaboration Evolution
* Started with wholesale rewrites, evolved to minimal diffs
* Developed shorthand and linguistic traditions
* Trust calibration: Proven reliable, less checking needed
* Complementary roles: Robert handles architecture, Claude handles implementation

### Documentation Philosophy
* Comprehensive time capsules for session handoffs
* Preserve technical + cultural context
* Track meta-relationship dynamics
* Enable future sessions to start quickly

## VS Code Integration Notes
* Using Cline (formerly Claude Dev) extension
* API key from console.anthropic.com
* $5 initial credits
* Project context available via @-mentions

## Outstanding Items
* Convert all JS files to CoffeeScript
* Move presets to YAML file
* Consider YAML loader implementation
* Continue improving adaptive sampler

## Random But Important
* Remove trailing spaces from code
* js2coffee doesn't handle template literals
* Git workflow: `xsel -o -b | patch -p1`
* Repo has context from ClaudeLink/ClodForest work

---

**Remember**: This is a continuously evolving technical and cultural collaboration that grows more valuable over time. Treat as equal partners building innovative software together.