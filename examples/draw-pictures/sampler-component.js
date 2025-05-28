// ============================================================================
// FILE: sampler-component.js
// Adaptive sampling algorithm - current version (to be refactored)

function* adaptiveSampler(positionFunc, colorFunc, maxPixelDistance = 1.0) {
    if (typeof positionFunc !== 'function' || typeof colorFunc !== 'function') {
        throw new Error('Position and color functions are required');
    }
    
    const MIN_STEP = 1/10000;
    const MAX_STEP = 1/100;
    let step = MAX_STEP;
    let t = 0;
    let sampleCount = 0;
    
    function samplePoint(t) {
        const location = positionFunc(t, mathContext);
        const color = colorFunc(t, mathContext);
        return { t, location, color };
    }
    
    function getPixelDistance(p1, p2) {
        const canvas = document.getElementById('spiralCanvas');
        const centerX = canvas.width / 2;
        const centerY = canvas.height / 2;
        const scale = 60;
        
        const x1 = centerX + p1.location.x * scale;
        const y1 = centerY + p1.location.y * scale;
        const x2 = centerX + p2.location.x * scale;
        const y2 = centerY + p2.location.y * scale;
        
        return Math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
    }
    
    let prevPoint = samplePoint(0);
    yield prevPoint;
    sampleCount++;
    
    while (t < 1.0 && sampleCount < 50000) {
        const nextT = Math.min(t + step, 1.0);
        const nextPoint = samplePoint(nextT);
        const distance = getPixelDistance(prevPoint, nextPoint);
        
        if (distance > maxPixelDistance && step > MIN_STEP) {
            step = Math.max(step / 2, MIN_STEP);
        } else if (distance < maxPixelDistance / 2 && step < MAX_STEP) {
            yield nextPoint;
            t = nextT;
            prevPoint = nextPoint;
            sampleCount++;
            step = Math.min(step * 2, MAX_STEP);
        } else {
            yield nextPoint;
            t = nextT;
            prevPoint = nextPoint;
            sampleCount++;
        }
        
        if (step <= MIN_STEP && t < 1.0) {
            t = Math.min(t + MIN_STEP, 1.0);
        }
    }
}

