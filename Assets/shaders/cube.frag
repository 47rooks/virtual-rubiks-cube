/*
 * Simple fragment shader to pass through the fragment color.
 */
varying vec2 vTexCoord;
varying vec4 vColor;

void main(void)
{
    // Produce black border around face color
    if (vTexCoord.x < 0.05 || vTexCoord.y < 0.05 || vTexCoord.x > 0.95 || vTexCoord.y > 0.95) {
        gl_FragColor = vec4(vec3(0.0), 1.0);
    } else {
        gl_FragColor = vColor;
    }
}