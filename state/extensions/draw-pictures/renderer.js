// Rendering functions
function renderCurrent() {
    const canvas = document.getElementById('spiralCanvas');
    const ctx = canvas.getContext('2d');

    if (!AppState.hasValidFunctions()) {
        status.textContent = "❌ No functions compiled yet";
        status.style.color = "#f44";
        return;
    }

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    try {
        ctx.strokeStyle = 'rgba(255,255,255,0.3)';
        ctx.lineWidth = 1;

        const canvasCenter = getCanvasCenter();
        const points = [];

        for (const sample of adaptiveSampler(AppState.getPositionFunc())) {
            const canvasCoords = scaleToCanvas(canvas, sample.location, canvasCenter);
            const color = AppState.getColorFunc()(sample.t, AppState.getMathContext());
            points.push({ canvas: canvasCoords, color: color, t: sample.t });
        }

        if (points.length > 0) {
            // Draw path
            ctx.beginPath();
            ctx.moveTo(points[0].canvas.x, points[0].canvas.y);
            for (let i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].canvas.x, points[i].canvas.y);
            }
            ctx.stroke();

            // Draw dots
            for (const point of points) {
                ctx.save();
                const r = Math.floor(Math.max(0, Math.min(1, point.color.r)) * 255);
                const g = Math.floor(Math.max(0, Math.min(1, point.color.g)) * 255);
                const b = Math.floor(Math.max(0, Math.min(1, point.color.b)) * 255);
                const a = Math.max(0, Math.min(1, point.color.a || 1));
                ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${a * 0.8})`;
                ctx.beginPath();
                ctx.arc(point.canvas.x, point.canvas.y, 2, 0, 2 * Math.PI);
                ctx.fill();
                ctx.restore();
            }
        }

        status.textContent = `✨ Rendered ${points.length} adaptive samples`;
        status.style.color = "#4f4";

    } catch (error) {
        const errorMsg = error.message.replace(/^.*?: /, '');
        status.textContent = `❌ Runtime error: ${errorMsg}`;
        status.style.color = "#f44";
    }
}

function clearCanvas() {
    const canvas = document.getElementById('spiralCanvas');
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    status.textContent = "Canvas cleared.";
    status.style.color = "#fff";
}

function renderWithDebugInfo() {
    const canvas = document.getElementById('spiralCanvas');
    const ctx = canvas.getContext('2d');

    if (!AppState.hasValidFunctions()) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const canvasCenter = getCanvasCenter();
    const debugData = [];

    // Create debug version of adaptive sampler
    function* debugAdaptiveSampler() {
        let t = 0;
        let step = samplerConfig.MAX_STEP;
        let sampleCount = 0;

        let currentPos = AppState.getPositionFunc()(0, AppState.getMathContext());
        yield { t: 0, location: currentPos, stepSize: step };
        sampleCount++;

        while (t < 1.0 && sampleCount < canvasConfig.MAX_SAMPLES) {
            const result = backtrackingNextPointFinder(
                t, currentPos, step, AppState.getPositionFunc(), samplerConfig
            );

            t = result.t;
            step = result.step;
            currentPos = result.pos;

            yield { t, location: currentPos, stepSize: step };
            sampleCount++;

            if (t >= 1.0) break;
        }
    }

    // Collect debug data
    for (const sample of debugAdaptiveSampler()) {
        const canvasCoords = scaleToCanvas(canvas, sample.location, canvasCenter);
        const color = AppState.getColorFunc()(sample.t, AppState.getMathContext());
        debugData.push({
            canvas: canvasCoords,
            color: color,
            t: sample.t,
            stepSize: sample.stepSize
        });
    }

    // Calculate step size range
    const stepSizes = debugData.map(d => d.stepSize);
    const maxStep = Math.max(...stepSizes);
    const minStep = Math.min(...stepSizes);

    // Draw dots with size based on step size
    for (const point of debugData) {
        const normalizedStep = maxStep > minStep ?
            (point.stepSize - minStep) / (maxStep - minStep) : 0;
        const dotSize = 2 + (1 - normalizedStep) * 3;

        ctx.save();
        const r = Math.floor(Math.max(0, Math.min(1, point.color.r)) * 255);
        const g = Math.floor(Math.max(0, Math.min(1, point.color.g)) * 255);
        const b = Math.floor(Math.max(0, Math.min(1, point.color.b)) * 255);
        ctx.fillStyle = `rgba(${r}, ${g}, ${b}, 0.9)`;
        ctx.beginPath();
        ctx.arc(point.canvas.x, point.canvas.y, dotSize, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();
    }

    status.textContent = `🔍 Debug: ${debugData.length} samples, ` +
        `step range: ${minStep.toExponential(2)} - ${maxStep.toExponential(2)}`;
    status.style.color = "#4f4";
}

function renderWithSampler(samplerFunc) {
    const canvas = document.getElementById('spiralCanvas');
    const ctx = canvas.getContext('2d');

    if (!AppState.hasValidFunctions()) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.strokeStyle = 'rgba(255,255,255,0.3)';
    ctx.lineWidth = 1;

    const canvasCenter = getCanvasCenter();
    const points = [];

    for (const sample of samplerFunc()) {
        const canvasCoords = scaleToCanvas(canvas, sample.location, canvasCenter);
        const color = AppState.getColorFunc()(sample.t, AppState.getMathContext());
        points.push({ canvas: canvasCoords, color: color, t: sample.t });
    }

    if (points.length > 0) {
        // Draw path
        ctx.beginPath();
        ctx.moveTo(points[0].canvas.x, points[0].canvas.y);
        for (let i = 1; i < points.length; i++) {
            ctx.lineTo(points[i].canvas.x, points[i].canvas.y);
        }
        ctx.stroke();

        // Draw dots
        for (const point of points) {
            ctx.save();
            const r = Math.floor(Math.max(0, Math.min(1, point.color.r)) * 255);
            const g = Math.floor(Math.max(0, Math.min(1, point.color.g)) * 255);
            const b = Math.floor(Math.max(0, Math.min(1, point.color.b)) * 255);
            const a = Math.max(0, Math.min(1, point.color.a || 1));
            ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${a * 0.8})`;
            ctx.beginPath();
            ctx.arc(point.canvas.x, point.canvas.y, 2, 0, 2 * Math.PI);
            ctx.fill();
            ctx.restore();
        }
    }

    status.textContent = `✨ Rendered ${points.length} samples`;
    status.style.color = "#4f4";
}

