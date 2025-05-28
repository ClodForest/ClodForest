// UI interaction handlers
const positionEditor = document.getElementById('positionCode');
const colorEditor = document.getElementById('colorCode');
const status = document.getElementById('status');

let compileTimeout = null;

function updateUIState(success, message) {
    status.textContent = success ? 
        "✅ Functions compiled successfully!" : 
        `❌ Compilation error: ${message}`;
    status.style.color = success ? "#4f4" : "#f44";
}

function compileUserFunctions() {
    try {
        const posCode = positionEditor.value;
        const colorCode = colorEditor.value;
        
        const { positionFunc, colorFunc } = compileFunctions(
            posCode, 
            colorCode, 
            AppState.getMathContext()
        );
        
        AppState.setFunctions(positionFunc, colorFunc);
        updateUIState(true);
        return true;
    } catch (error) {
        const errorMsg = error.message.replace(/^.*?: /, '');
        updateUIState(false, errorMsg);
        return false;
    }
}

function scheduleCompile() {
    clearTimeout(compileTimeout);
    compileTimeout = setTimeout(() => {
        if (compileUserFunctions()) renderCurrent();
    }, uiConfig.COMPILE_DELAY);
}

function handleEditorBlur() {
    if (compileUserFunctions()) renderCurrent();
}

// Centralized event listener setup
function initializeEventListeners() {
    positionEditor.addEventListener('input', scheduleCompile);
    positionEditor.addEventListener('blur', handleEditorBlur);
    colorEditor.addEventListener('input', scheduleCompile);
    colorEditor.addEventListener('blur', handleEditorBlur);
}

