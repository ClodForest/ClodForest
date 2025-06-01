// Sampling algorithms
function adaptiveStepCalculator(currentStep, distance, targetDistance, config) {
    const ratio = distance / targetDistance;
    if (ratio > 2.0) {
        // Too far - need smaller step
        return currentStep / ratio;
    } else if (ratio < 0.5) {
        // Too close - can use larger step
        return currentStep * 1.5;
    }
    return currentStep;
}

function backtrackingNextPointFinder(t, currentPos, currentStep, positionFunc, config) {
    const { MAX_ADAPTION_ATTEMPTS, MIN_STEP, MAX_STEP } = config;
    const targetFunctionDistance = 1.0 / getCanvasScale(); // Adaptive to zoom

    let step = currentStep;
    let bestStep = step;
    let bestDistance = Infinity;
    let bestPos = null;

    // Try to find optimal step size
    for (let attempt = 0; attempt < MAX_ADAPTION_ATTEMPTS; attempt++) {
        const newT = Math.min(t + step, 1.0);
        const newPos = positionFunc(newT, AppState.getMathContext());
        const distance = calculateFunctionSpaceDistance(currentPos, newPos);
        const error = Math.abs(distance - targetFunctionDistance);

        if (error < bestDistance) {
            bestDistance = error;
            bestStep = step;
            bestPos = newPos;
        }

        // Adjust step based on how far off we are
        step = adaptiveStepCalculator(step, distance, targetFunctionDistance, config);
        step = Math.max(MIN_STEP, Math.min(MAX_STEP, step));

        // Good enough?
        if (error < targetFunctionDistance * 0.1) break;
    }

    const finalT = Math.min(t + bestStep, 1.0);
    return {
        t: finalT,
        step: bestStep,
        pos: bestPos || positionFunc(finalT, AppState.getMathContext())
    };
}

function* adaptiveSampler(positionFunc, nextPointFinder = backtrackingNextPointFinder) {
    if (typeof positionFunc !== 'function') {
        throw new Error('Position function is required');
    }

    let step = samplerConfig.MAX_STEP;
    let sampleCount = 0;

    let currentPos = positionFunc(0, AppState.getMathContext());
    yield { t: 0, location: currentPos };
    sampleCount++;

    // Track recent points for curvature estimation
    let prevPos = null;
    let t = 0;

    while (t < 1.0 && sampleCount < canvasConfig.MAX_SAMPLES) {
        const result = nextPointFinder(t, currentPos, step, positionFunc, samplerConfig);

        // Estimate curvature to adjust step more intelligently
        if (prevPos && result.pos) {
            const curvature = estimateCurvature(prevPos, currentPos, result.pos);
            if (curvature > 0.1) {
                // High curvature area - reduce max step temporarily
                step = Math.min(step, samplerConfig.MAX_STEP / 2);
            }
        }

        t = result.t;
        step = result.step;
        prevPos = currentPos;
        currentPos = result.pos;

        yield { t, location: currentPos };
        sampleCount++;

        if (t >= 1.0) break;
    }
}

function fixedStepSampler(positionFunc, steps = 1000) {
    return function*() {
        for (let i = 0; i <= steps; i++) {
            const t = i / steps;
            const location = positionFunc(t, AppState.getMathContext());
            yield { t, location };
        }
    };
}
