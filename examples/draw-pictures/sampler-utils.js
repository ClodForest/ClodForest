// Sampler utility functions
function getCanvasScale() {
    return canvasConfig.SCALE;
}

function getCanvasCenter() {
    const canvas = document.getElementById('spiralCanvas');
    if (!canvas) return { x: 200, y: 200 };
    return { x: canvas.width / 2, y: canvas.height / 2 };
}

function pythagoras(p1, p2) {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    return Math.sqrt(dx * dx + dy * dy);
}

function makeClamper(min, max) {
    return (n) => Math.max(min, Math.min(max, n));
}

function calculateStepDistance(currentPos, newPos, scale) {
    const distance = pythagoras(currentPos, newPos);
    const maxPointDistance = canvasConfig.PIXEL_DISTANCE_THRESHOLD / scale;
    return Math.abs(distance - maxPointDistance);
}

function adjustStepSize(step, distance, clamp) {
    return clamp(step / distance);
}

function scaleToCanvas(canvas, location, center = null) {
    const actualCenter = center || getCanvasCenter();
    const scale = getCanvasScale();
    
    return {
        x: actualCenter.x + location.x * scale,
        y: actualCenter.y + location.y * scale
    };
}

