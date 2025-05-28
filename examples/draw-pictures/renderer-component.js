// ============================================================================
// FILE: renderer-component.js
// Canvas rendering and coordinate transformation

function renderCurrent() {
    const canvas = document.getElementById('spiralCanvas');
    const ctx = canvas.getContext('2d');
    
    if (!compiledPositionFunc || !compiledColorFunc) {
        status.textContent = "❌ No functions compiled yet";
        status.style.color = "#f44";
        return;
    }
    
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    try {
        const centerX = canvas.width / 2;
        const centerY = canvas.height / 2;
        const scale = 60;
        
        ctx.strokeStyle = 'rgba(255,255,255,0.3)';
        ctx.lineWidth = 1;
        
        const points = [];
        for (const point of adaptiveSampler(compiledPositionFunc, compiledColorFunc, 1.0)) {
            const canvasX = centerX + point.location.x * scale;
            const canvasY = centerY + point.location.y * scale;
            points.push({ x: canvasX, y: canvasY, color: point.color });
        }
        
        if (points.length > 0) {
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (let i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.stroke();
            
            for (const point of points) {
                ctx.save();
                const r = Math.floor(point.color.r * 255);
                const g = Math.floor(point.color.g * 255);
                const b = Math.floor(point.color.b * 255);
                const a = point.color.a || 1;
                ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${a * 0.8})`;
                ctx.beginPath();
                ctx.arc(point.x, point.y, 2, 0, 2 * Math.PI);
                ctx.fill();
                ctx.restore();
            }
        }
        
        status.textContent = `✨ Rendered ${points.length} points`;
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

