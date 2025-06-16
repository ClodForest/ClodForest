# CoffeeScript Language Summary

## Overview
CoffeeScript is a little language that compiles into JavaScript, exposing "the good parts of JavaScript in a simple way." It compiles one-to-one into readable JavaScript with no runtime interpretation.

## Core Philosophy
- "It's just JavaScript" - The golden rule
- Everything is an expression (as much as possible)
- Significant whitespace instead of curly braces
- No need to declare variables - compiler handles it
- Automatic safety wrapper prevents global namespace pollution

## Key Syntax Features

### Functions
```coffee
# No 'async' keyword needed - presence of 'await' makes it async
myAsyncFunction = -> 
  result = await somePromise()
  result

# No 'function*' needed - presence of 'yield' makes it a generator  
myGenerator = ->
  yield 1
  yield 2

# Fat arrow binds 'this' context
bound = => @property

# Default parameters
greet = (name = "World") -> "Hello #{name}"

# Splats (rest parameters)
sum = (first, rest...) -> first + rest.reduce ((a,b) -> a + b), 0
```

### Classes
```coffee
# ES2015 classes with CoffeeScript syntax
class Animal
  constructor: (@name) ->  # @ in parameters sets instance property
  
  move: (meters) ->
    console.log "#{@name} moved #{meters}m"

class Dog extends Animal
  move: ->
    console.log "Running..."
    super 5  # Must use explicit arguments or splat

# NO async keyword in constructors - constructors can't be async
```

### Important Differences from JavaScript

1. **No `var`, `let`, or `const`** - CoffeeScript has one type of variable
2. **No `async` keyword** - Functions with `await` are automatically async
3. **No `function*` syntax** - Functions with `yield` are generators
4. **`super` requires arguments** - Use `super arguments...` to forward all
5. **Constructors can't return values** - They must return the instance

### Control Flow
```coffee
# Postfix conditionals
console.log "It's true!" if condition
doSomething() unless error

# No ternary operator - use inline if/else
result = if condition then "yes" else "no"

# Switch statements prevent fall-through
switch day
  when "Monday" then work()
  when "Friday" then celebrate()
  else relax()
```

### Objects and Arrays
```coffee
# Optional commas, implicit braces
person =
  name: "Alice"
  age: 30
  greet: -> "Hi, I'm #{@name}"

# Destructuring with defaults
{name, age = 25} = person
[first, rest...] = array

# Ranges
numbers = [1..10]    # Inclusive: 1,2,3,4,5,6,7,8,9,10
numbers = [1...10]   # Exclusive: 1,2,3,4,5,6,7,8,9
```

### Loops and Comprehensions
```coffee
# Array comprehensions
squares = (x * x for x in [1..10])
evens = (x for x in numbers when x % 2 is 0)

# Object iteration  
for key, value of object
  console.log key, value

# Own properties only
for own key, value of object
  console.log key, value

# Array value iteration (ES6 for...of)
for value from array
  console.log value

# IMPORTANT: CoffeeScript 'from' → JavaScript 'of'
#           CoffeeScript 'of'   → JavaScript 'in'
```

### Operators and Aliases
```coffee
# CoffeeScript -> JavaScript
is          # === 
isnt        # !==
not         # !
and         # &&
or          # ||
@           # this
a in b      # array inclusion check
a of b      # object key check
```

### Existential Operator
```coffee
# Safe property access
user?.address?.street

# Existence check (not null or undefined)
if value?
  doSomething()

# Conditional assignment
cache ?= {}
```

### String Interpolation and Block Strings
```coffee
# Interpolation in double quotes
message = "Hello #{name}!"

# Block strings preserve formatting
html = """
  <div>
    <h1>#{title}</h1>
    <p>#{content}</p>
  </div>
  """

# Regex interpolation
pattern = ///
  \d+     # digits
  \.?     # optional decimal
  \d*     # optional fractional digits
///
```

## Common Gotchas

1. **No automatic `super` in constructors** - Unlike ES6 classes
2. **`this` before `super` is forbidden** in derived class constructors
3. **Implicit returns** - Functions always return their last value
4. **Indentation matters** - Mixing tabs/spaces is forbidden
5. **`@` parameter syntax** creates properties: `constructor: (@name) ->`

## CoffeeScript 2+ Features

- Outputs modern ES2015+ JavaScript
- JSX support built-in
- ES modules (`import`/`export`)
- Async/await support
- Object spread/rest syntax
- Supports most modern JS features

## What CoffeeScript Doesn't Support

- `let` and `const` (by design - one variable type)
- `get` and `set` keywords (use Object.defineProperty)
- Named function declarations (only expressions)
- Certain ES features until they reach Stage 4

## Browser/Runtime Requirements

- Compiler requires Node 6+
- Output runs in any modern JavaScript environment
- Use `--transpile` flag with Babel for older targets
- Source maps supported with `--map` flag