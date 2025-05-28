// Centralized state management
const AppState = {
    compiledPositionFunc: null,
    compiledColorFunc: null,
    mathContext: { 
        sin: Math.sin, 
        cos: Math.cos, 
        PI: Math.PI, 
        Tau: Math.PI * 2, 
        colorClamp: (x) => Math.max(0, Math.min(1, x)) 
    },
    
    getPositionFunc() { 
        return this.compiledPositionFunc; 
    },
    
    getColorFunc() { 
        return this.compiledColorFunc; 
    },
    
    getMathContext() { 
        return this.mathContext; 
    },
    
    setFunctions(positionFunc, colorFunc) {
        this.compiledPositionFunc = positionFunc;
        this.compiledColorFunc = colorFunc;
    },
    
    hasValidFunctions() {
        return this.compiledPositionFunc && this.compiledColorFunc;
    }
};

