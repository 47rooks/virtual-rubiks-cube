/*
 * Simple fragment shader to pass through the fragment color.
 */
varying vec4 vColor;

void main(void)
{
    gl_FragColor = vColor;
}