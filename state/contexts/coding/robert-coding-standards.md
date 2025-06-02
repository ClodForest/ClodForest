# Robert's Coding Standards

## Core Philosophy

### Function Size & Complexity
- **Target**: Functions under 10 lines without compromising clarity
- **Inspiration**: FORTH/Lisp style where large functions are "out of the question for sane programmers"
- **Principle**: Build complexity from simple, composable pieces

### Fourth Normal Form Refactoring
- Extract transformation functions (like `.map` operations)
- Separate data validation, transformation, and composition
- Make transformations explicit and reusable
- Example: `[r, g, b] = [color.r, color.g, color.b].map scale`

## Visual Alignment & Whitespace

### Vertical Alignment Philosophy
- Align similar operations to show relationships
- Answer "why is it this way" questions without text comments
- Emphasize similarities and differences between lines

```coffee
# Good: Shows parallel structure
{ status : document.getElementById 'status'
  canvas : document.getElementById 'spiralCanvas'
  ctx    : canvas  .getContext     '2d'
}
```

### Horizontal & Vertical Whitespace
- **Blank lines**: Separate conceptual blocks
- **Indentation**: Highlight transformations (`.map` calls indented)
- **Alignment**: Group related operations visually

### Shape Matching Intention
- When one line looks different from others, find ways to make them harmonious
- Transform code blocks to make alignment easier
- Don't let extremism interfere with beauty - balance alignment with efficiency

## Code Organization

### Minimal Diffs Principle
- Use surgical changes over wholesale rewrites
- Address all related code locations in one pass
- Preserve working functionality while improving structure

### Duplicate Code Elimination
- Extract common patterns into reusable functions
- Centralize DOM access, status updates, color conversion
- Create specialized variants (e.g., `drawDots` vs `drawDebugDots`) when needed

### Function Naming
- Use verb-noun pattern (`drawPath`, `setupCanvas`, `updateStatus`)
- Descriptive but concise names
- Clear input/output relationships

## CoffeeScript Preferences

### Language Features
- Implicit returns and comprehensions
- Significant whitespace for structure
- Object destructuring: `{ status, canvas, ctx } = theWorld()`
- Conditional assignment: `a or= 1`

### Aesthetic Choices
- Function-driven beauty over diff-friendliness
- Vertical alignment over horizontal compactness
- Clarity over cleverness

## Technology Stack Preferences

### Languages & Formats
- **CoffeeScript** > Perl5, avoid C++
- **YAML** for config/serialization
- **SQLite** for local persistence

### Tools & Philosophy
- Unix philosophy: small, focused tools that work together
- Vim, publicfile (DJB tools), HHKB aesthetics
- Open standards: IETF, W3C, Mozilla, EFF, Devuan, FSF

## Quality Standards

### Error Handling
- Graceful degradation with user feedback
- Centralized status/error reporting
- Clear error messages without technical jargon

### Performance Philosophy
- "The simplest thing that could possibly work"
- "The minimum effective dose"
- Optimize for readability first, performance second
- Avoid premature optimization

## Communication in Code

### Comments & Documentation
- Let code structure tell the story
- Use alignment and naming to reduce comment needs
- Document architectural decisions, not implementation details

### Collaboration Style
- Equal partnership approach
- Trust calibration: proven reliable code needs less checking
- Complementary roles: architecture vs implementation

---

*"Treat our partnership as a continuously evolving technical and cultural collaboration that grows more valuable over time."*
