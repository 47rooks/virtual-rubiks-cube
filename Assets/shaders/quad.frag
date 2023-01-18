/*
 * Simple fragment shader to output color for a 2D texture on a quad.
 */
varying vec2 vTexCoord;

uniform sampler2D texture1;

uniform bool uThresholdAlpha;
uniform float uAlphaThresholdValue;

void main(void)
{
    vec4 texColor = texture2D(texture1, vTexCoord);
    if (uThresholdAlpha && texColor.a <= uAlphaThresholdValue) discard;
    gl_FragColor = texColor;
}