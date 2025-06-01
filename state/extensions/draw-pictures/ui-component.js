// ============================================================================
// FILE: ui-component.js
// Function editor, compilation, and auto-compile triggers

const positionEditor = document.getElementById('positionCode');
const colorEditor = document.getElementById('colorCode');
const status = document.getElementById('status');

let compileTimeout = null;
let compiledPositionFunc = null;
let compiledColorFunc = null;

const mathContext = {
    sin: Math.sin, cos: Math.cos, PI: Math.PI,
    Tau: Math.PI * 2, colorClamp: (x) => Math.max(0, Math.min(1, x))
};

function compileUserFunctions() {
    try {
        const posCode = positionEditor.value;
        const colorCode = colorEditor.value;

        const newPositionFunc = new Function('t', 'ctx', `
            const {sin, cos, PI, Tau} = ctx;
            ${posCode}
        `);

        const newColorFunc = new Function('t', 'ctx', `
            const {sin, cos, PI, Tau, colorClamp} = ctx;
            ${colorCode}
        `);

        newPositionFunc(0, mathContext);
        newColorFunc(0, mathContext);

        compiledPositionFunc = newPositionFunc;
        compiledColorFunc = newColorFunc;

        status.textContent = "✅ Functions compiled successfully!";
        status.style.color = "#4f4";
        return true;
    } catch (error) {
        const errorMsg = error.message.replace(/^.*?: /, '');
        status.textContent = `❌ Compilation error: ${errorMsg}`;
        status.style.color = "#f44";
        return false;
    }
}

function scheduleCompile() {
    clearTimeout(compileTimeout);
    compileTimeout = setTimeout(() => {
        if (compileUserFunctions()) renderCurrent();
    }, 3000);
}

positionEditor.addEventListener('input', scheduleCompile);
positionEditor.addEventListener('blur', () => {
    if (compileUserFunctions()) renderCurrent();
});
colorEditor.addEventListener('input', scheduleCompile);
colorEditor.addEventListener('blur', () => {
    if (compileUserFunctions()) renderCurrent();
});

