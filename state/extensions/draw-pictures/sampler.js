// Sampling algorithms
function linearNextPointFinder(t, currentPos, currentStep, positionFunc, config) {
    const { MAX_ADAPTION_ATTEMPTS, MAX_DISTANCE_EPSILON, MIN_STEP, MAX_STEP } = config;
    const clamp = makeClamper(MIN_STEP, MAX_STEP);
    const scale = getCanvasScale();
    
    let step = currentStep;
    
    for (let attempts = 0; attempts < MAX_ADAPTION_ATTEMPTS; attempts++) {
        const newT = Math.min(t + step, 1.0);
        const newPos = positionFunc(newT, AppState.getMathContext());
        
        const distanceError = calculateStepDistance(currentPos, newPos, scale);
        
        if (distanceError <= MAX_DISTANCE_EPSILON) {
            return { t: newT, step, pos: newPos, attempts };
        }
        
        step = adjustStepSize(step, distanceError, clamp);
    }
    
    const newT = Math.min(t + step, 1.0);
    const newPos = positionFunc(newT, AppState.getMathContext());
    return { t: newT, step, pos: newPos, attempts: MAX_ADAPTION_ATTEMPTS };
}

function* adaptiveSampler(positionFunc, nextPointFinder = linearNextPointFinder) {
    if (typeof positionFunc !== 'function') {
        throw new Error('Position function is required');
    }
    
    let t = 0;
    let step = samplerConfig.MAX_STEP;
    let sampleCount = 0;
    
    let currentPos = positionFunc(0, AppState.getMathContext());
    yield { t: 0, location: currentPos };
    sampleCount++;
    
    while (t < 1.0 && sampleCount < canvasConfig.MAX_SAMPLES) {
        const result = nextPointFinder(t, currentPos, step, positionFunc, samplerConfig);
        
        t = result.t;
        step = result.step;
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

