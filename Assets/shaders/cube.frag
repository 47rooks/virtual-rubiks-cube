/*
 * Simple fragment shader to pass through the fragment color.
 */
varying vec2 vTexCoord;
varying vec4 vColor;

void main(void)
{
    // Get a soft border float value
    float bLowX = smoothstep(0.03, 0.05, vTexCoord.x);
    float bHighX = 1.0 - smoothstep(0.95, 0.97, vTexCoord.x);
    float bLowY = smoothstep(0.03, 0.05, vTexCoord.y);
    float bHighY = 1.0 - smoothstep(0.95, 0.97, vTexCoord.y);
    
    // Produce black border around face color
    if (vTexCoord.x <= 0.03 || vTexCoord.y < 0.03 || vTexCoord.x >= 0.97 || vTexCoord.y >= 0.97) {
        gl_FragColor = vec4(vec3(0.0), 1.0);
    } else {
        vec3 color = vColor.rgb * bLowX * bHighX * bLowY * bHighY;
        gl_FragColor = vec4(color, 1.0);
    }
}