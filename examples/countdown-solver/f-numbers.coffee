
# Because F numbers!

# Haha, kidding. The F is for functional, as opposed to OO.

simpleOp = (fn) -> doIt: fn, can: (stack) -> stack.length > 1

countSkips = (history) ->
  history
    .filter (x) -> x is 'skip'
    .length

ops =
  add : simpleOp ([a, b, rest...]) -> [a + b, rest...]
  sub :
    doIt: ([a, b, rest...]) -> [a - b, rest...]
    can : ([a, b]) -> a > b

  mul :
    doIt: ([a, b, rest...]) -> [a * b, rest...]
    can :  (stack) -> stack.length > 1 and 1 not in stack[0..1]

  div :
    doIt: ([a, b, rest...]) -> [a / b, rest...]
    can : (stack) -> (stack.length > 1) and not (stack[0] % stack[1])

  skip:
    doIt: ([head, rest...]) -> [rest..., head]
    can : (stack, history) -> stack.length - 1 > countSkips history

if false
  drop:
    doIt: ([a, rest...]) -> rest
    can : (stack) -> stack.length > 1

  swap:
    doIt: ([a, b, rest...]) -> [b, a, rest...]
    can : (stack, history) ->
      history[0] isnt 'swap' and
      stack.length > 1       and
      stack[0] isnt stack[1]
      

withoutNth = (n, haystack) ->
  haystack = [].concat haystack # make a copy
  haystack.splice n, 1
  haystack


without = (needle, haystack) ->
  idx = haystack.indexOf needle
  withoutNth idx, haystack


sortLists = (a, b) ->
  for x, i in a
    if x isnt y = b[i]
      return x - y

  0


uniq =
  (a, x) ->
    return [x] unless a.length

    for y in a
      if 0 is sortLists x, y
        return a
    
    [a..., x]


permute = (numbers) ->
  if numbers.length > 1
    [].concat (
      for x, i in numbers
        for suffix in permute withoutNth i, numbers
          [x].concat suffix
    )...
  else
    [numbers]


solve = (goal, numbers, history = []) ->
  if numbers[0] is goal
    return []

  for name, {doIt, can} of ops
    if can numbers, history
      newNumbers = doIt numbers

      if steps = solve goal, newNumbers, [name, history...]
        return [name, steps...]

  return null


solveAll = (goal, numbers, maxSolutions = 720) ->
  solutions = []

  permutations =
    (permute numbers)
      .sort sortLists
      .reduce uniq, []

  for permutation in permutations
    if solution = solve goal, permutation
      if solution[0] isnt 'skip'
        solutions.push [permutation, solution]

        if solutions.length >= maxSolutions
          break

  return solutions


show = (numbers, steps) ->
  lines = []

  for step in steps
    [a, b, rest...] = numbers

    if not ops[step]      then throw new Error "Unknown step '#{step}'"
    if not ops[step].doIt then throw new Error "Step '#{step}' has no 'doIt'"

    [c] = numbers = ops[step].doIt numbers

    if step not in [ 'skip', 'drop' ]
      #lines.push "#{a} #{step} #{b} -> #{c} (#{numbers.join ' '})"
      lines.push "#{a} #{step} #{b} -> #{c}"

  lines

parseNumbersPuzzle = (puzzle) ->
  [goal, numbers...] =
    puzzle
      .split /\s+/
      .map (s) -> parseInt s
  {goal, numbers}

numbersGame = (puzzle, all = yes) ->
  {goal, numbers} = parseNumbersPuzzle puzzle

  solutions = solveAll goal, numbers

  if not all
    solutions =
      solutions
        .sort (a, b) -> a.length - b.length
        .at 0

  solutions.forEach (solution) -> console.log show numbers, solution

module.exports = {ops, solve, solveAll, show}

if false
  demo = (pstr) ->
    [goal, numbers...] = pstr.split /\s+/
    solveAll goal, numbers

  demo "904  25  75  3  8  4  1"

  test = (goal, numbers, path) ->
    if result = solve goal, numbers
      console.log "#{goal} from [#{numbers.join ' '}]: #{result.join ' '}"
    else
      console.log "#{goal} from [#{numbers.join ' '}]: impossibru!"


  test 1, []
  test 1, [2   ]
  test 1, [2, 3]

  test 1, [1   ] ,          "done"
  test 2, [3, 2] ,     "skip done"

  test 2, [1, 1] ,      "add done"
  test 4, [6, 2] ,      "sub done"
  test 6, [2, 3] ,      "mul done"

  test 3, [6, 2] ,      "div done"

  test 4, [2, 6] , "skip sub done"

  test 27, [     3, 3, 3],      "mul mul done"
  test 27, [131, 3, 3, 3], "skip mul mul done"

  test 930, [25, 50, 9, 6, 4, 10]
  test 981, [9, 8, 8, 7, 5, 4],
    "mul skip skip skip skip add "
    # 72 8 8 7 5 4
  # (9 * 8 + 4) * (8 + 5) - 7

  console.log show [25, 50, 9, 6, 4, 10], solve 930, [25, 50, 9, 6, 4, 10]

if false
  for solution in solveAll 930, numbers = [25, 50, 9, 6, 4, 10]
    console.log show numbers, solution
