/*
 * Simple fragment shader to output color for a 2D texture on an NDC quad.
 */
varying vec2 vTexCoord;

uniform sampler2D texture1;

void main(void)
{
    gl_FragColor = texture2D(texture1, vTexCoord);
}