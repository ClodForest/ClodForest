# CoffeeScript Gotchas & Python/JavaScript Comparison

## Critical CoffeeScript Facts

### 1. **NO `async` keyword exists in CoffeeScript**
```coffee
# WRONG - This is a syntax error!
async myFunction = ->

# RIGHT - Just use await, function becomes async automatically
myFunction = ->
  result = await somePromise()
```

### 2. **`super` in constructors requires explicit call**
```coffee
# WRONG - Unlike Python, super doesn't auto-call in CoffeeScript
class Child extends Parent
  constructor: ->
    @property = "value"  # Error! Can't use @ before super

# RIGHT
class Child extends Parent
  constructor: ->
    super()  # or super(args...)
    @property = "value"
```

### 3. **`super` requires arguments or splat**
```coffee
# WRONG - Bare super doesn't forward arguments
method: -> super

# RIGHT
method: -> super arguments...  # Forward all
method: -> super()             # Call with no args
```

## Python → CoffeeScript Gotchas

### 1. **Indentation & Line Continuations**
```python
# Python - backslash for line continuation
long_list = [1, 2, 3, \
             4, 5, 6]
```

```coffee
# CoffeeScript - leading operators or indentation
long_list = [1, 2, 3,
             4, 5, 6]

# Or with operators
result = something +
  somethingElse +
  andMore
```

### 2. **Instance Variables**
```python
# Python - explicit self parameter
class Dog:
    def __init__(self, name):
        self.name = name
```

```coffee
# CoffeeScript - @ is this, auto-binding in parameters
class Dog
  constructor: (@name) ->  # Sets @name = name automatically
```

### 3. **List/Array Comprehensions**
```python
# Python
squares = [x**2 for x in range(10) if x % 2 == 0]
```

```coffee
# CoffeeScript - 'when' instead of 'if'
squares = (x**2 for x in [0..9] when x % 2 is 0)
```

### 4. **Generators**
```python
# Python - explicit yield
def my_generator():
    yield 1
    yield 2
```

```coffee
# CoffeeScript - no special syntax needed
myGenerator = ->
  yield 1
  yield 2
```

### 5. **String Formatting**
```python
# Python f-strings
name = "Alice"
message = f"Hello {name}!"
```

```coffee
# CoffeeScript interpolation
name = "Alice"
message = "Hello #{name}!"
```

### 6. **Dictionary/Object Iteration**
```python
# Python
for key, value in my_dict.items():
    print(key, value)
```

```coffee
# CoffeeScript - 'of' for objects, 'in' for arrays
for key, value of myObject
  console.log key, value

# BUT BEWARE: 'from' iterates array values (compiles to JS 'of')
for value from myArray
  console.log value
```

### 7. **Default Mutable Arguments** (The Big One!)
```python
# Python DANGER - mutable default
def add_item(item, list=[]):  # DON'T DO THIS
    list.append(item)
    return list
```

```coffee
# CoffeeScript - same danger exists!
addItem = (item, list = []) ->  # DON'T DO THIS
  list.push item
  list

# Both languages: use null/None pattern
addItem = (item, list = null) ->
  list ?= []  # CoffeeScript
  list.push item
```

## JavaScript → CoffeeScript Gotchas

### 1. **The Great Iterator Keyword Swap** 🤦
This is perhaps the most confusing gotcha between CoffeeScript and modern JavaScript:

```coffee
# CoffeeScript
for item from array
  console.log item    # Iterates over VALUES (ES6 for...of)

for key of object
  console.log key     # Iterates over KEYS (for...in)
```

```javascript
// JavaScript - SWAPPED!
for (item of array) {
  console.log(item);  // Values - but using 'of' not 'from'
}

for (key in object) {
  console.log(key);   // Keys - but using 'in' not 'of'
}
```

**Memory trick**: CoffeeScript's `from` pulls values FROM an array, while `of` gets properties OF an object. JavaScript... just swapped them. 🤷

### 2. **Variable Declaration**
```javascript
// JavaScript
let x = 5;        // Block scoped
const y = 10;     // Constant
var z = 15;       // Function scoped
```

```coffee
# CoffeeScript - Only one way
x = 5
y = 10  # Not really constant!
z = 15
```

### 2. **Async/Await**
```javascript
// JavaScript
async function fetchData() {
  const result = await fetch(url);
  return result;
}
```

```coffee
# CoffeeScript - No async keyword
fetchData = ->
  result = await fetch url
  result  # Implicit return
```

### 3. **Arrow Functions & `this`**
```javascript
// JavaScript
const obj = {
  method: function() {
    setTimeout(() => {
      console.log(this);  // Bound to obj
    }, 1000);
  }
};
```

```coffee
# CoffeeScript
obj =
  method: ->
    setTimeout =>
      console.log @  # => binds this
    , 1000
```

### 4. **Destructuring Differences**
```javascript
// JavaScript - can use in function parameters
function process({name, age = 25}) {
  console.log(name, age);
}
```

```coffee
# CoffeeScript - same syntax
process = ({name, age = 25}) ->
  console.log name, age
```

### 5. **Template Literals**
```javascript
// JavaScript
const multiline = `Line 1
Line 2
Line 3`;
```

```coffee
# CoffeeScript - triple quotes
multiline = """
  Line 1
  Line 2
  Line 3
  """
```

## Shared Python/JavaScript → CoffeeScript Gotchas

### 1. **Equality Operators**
```python
# Python
x == y   # Value equality
x is y   # Identity equality
```

```javascript
// JavaScript
x == y   // Loose equality (avoid!)
x === y  // Strict equality
```

```coffee
# CoffeeScript
x == y   # Compiles to === (strict)
x is y   # Also compiles to === 
```

### 2. **Falsy Values**
All three languages have different ideas of "falsy":

```python
# Python falsy: False, None, 0, "", [], {}, ()
```

```javascript
// JavaScript falsy: false, null, undefined, 0, "", NaN
```

```coffee
# CoffeeScript - same as JavaScript
# BUT existential operator helps:
value ? defaultValue  # Only false for null/undefined
```

### 3. **Function Returns**
```python
# Python - explicit return needed
def add(a, b):
    a + b  # Returns None!
```

```javascript
// JavaScript - explicit return needed
function add(a, b) {
  a + b;  // Returns undefined!
}
```

```coffee
# CoffeeScript - implicit return
add = (a, b) ->
  a + b  # Returns the sum!
```

### 4. **Class Properties**
```python
# Python - class variables shared
class Dog:
    tricks = []  # Shared by all instances!
```

```javascript
// JavaScript - in class body
class Dog {
  tricks = [];  // Instance property (ES2022+)
}
```

```coffee
# CoffeeScript - use constructor for instance properties
class Dog
  constructor: ->
    @tricks = []  # Instance property
```

## CoffeeScript-Specific Gotchas

### 1. **Implicit Function Calls**
```coffee
# These are all function calls!
console.log "Hello"
Math.sqrt 16
alert "Warning"

# Can lead to surprises:
fn x, y for y in list  # Might not do what you expect
```

### 2. **Significant Whitespace in Objects**
```coffee
# This works
obj = {
  a: 1
  b: 2
}

# This also works (implicit braces)
obj =
  a: 1
  b: 2

# But be careful with returns
return
  a: 1  # Returns undefined! (statement on next line)

return a: 1  # Returns {a: 1}
```

### 3. **Reserved Words as Properties**
```coffee
# These are fine in CoffeeScript 2+
obj =
  class: "foo"
  for: "bar"
  if: "baz"
```

### 4. **Operator Precedence Surprises**
```coffee
# Exponentiation binds tighter than unary minus
-2 ** 2  # Returns -4, not 4

# Use parentheses
(-2) ** 2  # Returns 4
```

### 5. **Do Block Gotcha**
```coffee
# 'do' immediately invokes the function
for x in [1..3]
  do (x) ->
    setTimeout (-> console.log x), 100

# Without 'do', all would print 3
```

## Best Practices to Avoid Gotchas

1. **Always use `super arguments...` or `super()` explicitly**
2. **Use `?` operator instead of checking for null/undefined manually**
3. **Be explicit with parentheses for complex expressions**
4. **Use `own` when iterating object properties you defined**
5. **Remember everything returns a value - be careful with implicit returns**
6. **Use fat arrow `=>` when you need to preserve `this` context**
7. **Don't rely on variable hoisting - CoffeeScript handles it differently**
8. **Test edge cases with `null`, `undefined`, `0`, `""`, and `false`**
9. **Use explicit parentheses for function calls with complex arguments**
10. **Remember: No `async`, no `const`, no `let` - embrace the simplicity**

## The Golden Rule

When in doubt, check the compiled JavaScript! CoffeeScript's output is readable and will show you exactly what your code is doing:

```bash
coffee -c -b myfile.coffee  # Compile bare (no wrapper) to see output
```