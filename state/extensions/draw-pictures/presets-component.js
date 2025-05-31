// ============================================================================
// FILE: presets-component.js
// Mathematical function presets for quick experimentation

const presets = {
    original: {
        position: `const tRadians = t * 2 * PI;
return {
  x: sin(tRadians) * 2,
  y: cos(tRadians) * 3
};`,
        color: `const oneThirdCircle = (whichThird) => (Tau / 3) * whichThird;
return {
  r: colorClamp(sin(t + oneThirdCircle(0))),
  g: colorClamp(sin(t + oneThirdCircle(1))),
  b: colorClamp(sin(t + oneThirdCircle(2))),
  a: 1
};`
    },
    
    spiral: {
        position: `const angle = t * 8 * PI;
const radius = t;
return {
  x: cos(angle) * radius,
  y: sin(angle) * radius
};`,
        color: `return {
  r: t,
  g: 1 - t,
  b: sin(t * PI) * 0.5 + 0.5,
  a: 1
};`
    },
    
    lissajous: {
        position: `return {
  x: sin(t * 3 * PI),
  y: sin(t * 2 * PI)
};`,
        color: `return {
  r: (sin(t * 4 * PI) + 1) * 0.5,
  g: (cos(t * 6 * PI) + 1) * 0.5,
  b: (sin(t * 8 * PI + PI/2) + 1) * 0.5,
  a: 1
};`
    },
    
    rose: {
        position: `const k = 5;
const angle = t * 2 * PI;
const r = sin(k * angle);
return {
  x: r * cos(angle),
  y: r * sin(angle)
};`,
        color: `const hue = t * 6;
return {
  r: (sin(hue) + 1) * 0.5,
  g: (sin(hue + 2) + 1) * 0.5,
  b: (sin(hue + 4) + 1) * 0.5,
  a: 1
};`
    }
};

function loadPreset(name) {
    if (presets[name]) {
        positionEditor.value = presets[name].position;
        colorEditor.value = presets[name].color;
        if (compileUserFunctions()) renderCurrent();
    }
}

