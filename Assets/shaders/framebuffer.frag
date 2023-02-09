/*
 * Simple fragment shader to output color for a 2D texture on a quad. It supports the following post-processing effects.
 *
 *     Grayscale, color inversion (1-rgb).
 */
varying vec2 vTexCoord;

uniform sampler2D texture1;

/* Post-processing effects */
uniform bool uInversion;
uniform bool uGrayscale;

void main(void)
{
    vec4 texColor = texture2D(texture1, vTexCoord);
    if (texColor.a > 0.0) {
        if (uInversion) {
            gl_FragColor = vec4(vec3(1.0 - texColor), 1.0);
        } else if (uGrayscale) {
            gl_FragColor = vec4(vec3(texColor.r * 0.2126 + texColor.g * 0.7152 + texColor.b * 0.0722), 1.0);
        } else
        {
            gl_FragColor = vec4(texColor.r, texColor.g, texColor.b, 1.0);
        }
    } else {
        gl_FragColor = vec4(texColor.r, texColor.g, texColor.b, 1.0);
    }
}