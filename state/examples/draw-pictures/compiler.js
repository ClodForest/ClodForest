// Function compilation utilities
function createFunction(code, contextVars) {
    const varList = contextVars.join(', ');
    return new Function('t', 'ctx', `
        const {${varList}} = ctx;
        ${code}
    `);
}

function validateFunction(func, context) {
    func(0, context);
    return true;
}

function compileFunctions(positionCode, colorCode, mathContext) {
    const positionFunc = createFunction(positionCode, ['sin', 'cos', 'PI', 'Tau']);
    const colorFunc = createFunction(colorCode, ['sin', 'cos', 'PI', 'Tau', 'colorClamp']);
    
    validateFunction(positionFunc, mathContext);
    validateFunction(colorFunc, mathContext);
    
    return { positionFunc, colorFunc };
}

