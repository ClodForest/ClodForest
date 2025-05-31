# invoke with 't' between 0 and 1 to reveal a shape.
# 
# Returns [{x, y}, {r, g, b, a}]
#
# x and y          are in range [-1.0 .. 1.0]
# colors and alpha are in range [ 0.0 .. 1.0]

{sin, cos, min, max, PI} = Math

Tau = PI * 2

clamp = (least, most) -> (number) -> max least, min most, number

colorClamp      = clamp  0, 1
coordinateClamp = clamp -1, 1

# t is in radians
rainbow = (t) ->
  oneThirdCircle = (whichThird) = (Tau / 3) * whichThird
  r: colorClamp sin t + oneThirdCircle 0
  g: colorClamp sin t + oneThirdCircle 1
  b: colorClamp sin t + oneThirdCircle 2
  a: 1

samplePixel = (t) ->
  t *= 2 * PI # convert to radians/tau scale

  location =
    x: sin t * 2
    y: cos t * 3

  color = rainbow t

  [location, color]


###
Good job, I think these divisions will work well. I see they're all barely under 50 lines, so let's consider the max size 100 lines while we do some editing and then think about a re-factor and breaking stuff apart again after that.

Suggestions

Abstract out and simplify step adjustment: In Sampler Component, the infinite loop avoidance at the bottom of adaptiveSampler seems unnecessarily complicated to me. Let's re-factor and simplify it: split the next point discovery into its own function with parameters of: positionFunction, t, current/min/max step size. Have the function try to guess the ideal step size by finding out how many pixels away the next step is and dividing the step size by that. If the step size is less than one pixel's worth, dividing by that distance will make it grow, hopefully the right amount. Repeat that process a maximum of three times and keep track of how many times the process had to be repeated before (1 - the distance between the points ) < PIXEL_DISTANCE_EPSILON, which we'll say is 0.1 to start with?

Then, pass that nextLocationFinder function in to the adaptive sampler as an injected dependency so we can experiment with different functions later.

More separation of concerns: Leave the color lookups to the render pass and have the adaptive sampler only calculate points.

Move real constants outside of functions: in getPixelDistance you're re-calculating centerX and centerY every time you compare two locations. Move that one scope out and make it its own function. It's fine for getPixelDistance to receive those values from the outer scope:
###

    config =
      MIN_STEP:              1/10000
      MAX_STEP:              1/100
      MAX_ADAPTION_ATTEMPTS: 3
      MAX_POINT_DISTANCE:    2   / canvasScale() # approximate function-space size of canvas pixels
      MAX_DISTANCE_EPSILON:  0.1 / canvasScale()

    # Since we're only comparing this distance to MAX_POINT_DISTANCE, we don't have to take a square root, we can just compare it to MAX_POINT_DISTANCE**2
    pythagoras = (p1, p2) -> Math.sqrt (p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2

    makeClamper = (min, max) -> (n) -> Math.max min, Math.min max, n

    # This could go in its own file/artifact/module/whatever
    linearNextPointFinder = (t, currentPos, currentStep, positionFunc, config) ->
      { MAX_ADAPTION_ATTEMPTS
        MAX_DISTANCE_EPSILON
        MIN_STEP
        MAX_STEP
      } = config

      iterations = 0
      step = currentStep
      clamp = makeClamper MIN_STEP, MAX_STEP

      loop
        # evaluate current step size
        newT = t + step
        newPos = positionFunc newT

        if ++iterations >= MAX_ADAPTION_ATTEMPTS
          return {t: newT, step, pos: newPos, iterations}

        distance      = pythagoras currentPos, newPos
        distanceError = Math.abs distance - MAX_POINT_DISTANCE

        if MAX_DISTANCE_EPSILON >= distanceError
          return {t: newT, step, iterations}

        # scale step size inversely with pixel distance
        step = clamp step / distance


    adaptiveSampler = (positionFunc, nextPointFinder) ->
      if 'function' isnt typeof positionFunc or
         'function' isnt typeof colorFunc
        throw new Error "..."


###
Document with functions: It's not immediately obvious what const scale = 60; is for. I do see that it's for scaling the [-1..1] dimensions up to canvas size, but that should probably be handled in a function like scaleToCanvas(canvas, {x, y}, center: {x, y})

I anticipate my way may have some pathological performance problems, but we'll worry about that later.
###
