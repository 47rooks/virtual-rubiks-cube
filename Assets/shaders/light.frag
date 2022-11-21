/*
 * Simple fragment shader to set the color of the light.
 */
varying vec4 vColor;

uniform vec3 uLightColor;
uniform bool u3CompLightEnabled;

void main(void)
{
    if (u3CompLightEnabled) {
        // If 3-component light is enabled set object color
        gl_FragColor = vec4(uLightColor / 255.0, 1.0);
    } else {
        gl_FragColor = vColor;
    }
}