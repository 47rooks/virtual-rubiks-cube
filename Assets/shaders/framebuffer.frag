#version 120
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
uniform bool uSharpen;
uniform bool uBlur;
uniform bool uEdgeDetection;

const float offset = 1.0 / 300.0;

vec3 applyKernel(vec2 pos, float[9] kernel)
{
    vec2 offsets[9] = vec2[](
        vec2(-offset,  offset), // top left
        vec2(    0.0,  offset), // top-center
        vec2( offset,  offset), // top-right
        vec2(-offset,     0.0), // center-left
        vec2(    0.0,     0.0), // center
        vec2( offset,     0.0), // center-right
        vec2(-offset, -offset), // bottom-left
        vec2(    0.0, -offset), // bottom-center
        vec2( offset, -offset)  // bottom-right
    );
    vec3 sampleTex[9];
    for (int i=0; i < 9; i++) {
        sampleTex[i] = vec3(texture2D(texture1, pos.xy + offsets[i]));
    }

    vec3 color = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        color += sampleTex[i] * kernel[i];
    }
    return color;
}

/* Sharpen the image */
vec3 sharpen(vec2 pos) {
    float kernel[9] = float[](
        -1.0, -1.0, -1.0, -1.0, 9.0, -1.0, -1.0, -1.0 ,-1.0
    );
    return applyKernel(pos, kernel);
}

/* Blur the image with a simple blur kernel. */
vec3 blur(vec2 pos) {
    float kernel[9] = float[](
        1.0 / 16, 2.0 / 16, 1.0 / 16, 2.0 / 16, 4.0 / 16, 2.0 / 16, 1.0 / 16, 2.0 / 16 , 1.0 / 16
    );
    return applyKernel(pos, kernel);
}

/* Perform a simple edge detection */
vec3 edgeDetection(vec2 pos) {
    float kernel[9] = float[](
        1.0, 1.0, 1.0, 1.0, -8.0, 1.0, 1.0, 1.0, 1.0
    );
    return applyKernel(pos, kernel);
}

void main(void)
{
    vec4 texColor = texture2D(texture1, vTexCoord);
    if (texColor.a > 0.0) {
        if (uInversion) {
            gl_FragColor = vec4(vec3(1.0 - texColor), 1.0);
        } else if (uGrayscale) {
            gl_FragColor = vec4(vec3(texColor.r * 0.2126 + texColor.g * 0.7152 + texColor.b * 0.0722), 1.0);
        } else if (uSharpen) {
            gl_FragColor = vec4(sharpen(vTexCoord), 1.0);
        } else if (uBlur) {
            gl_FragColor = vec4(blur(vTexCoord), 1.0);
        } else if (uEdgeDetection) {
            gl_FragColor = vec4(edgeDetection(vTexCoord), 1.0);
        } else
        {
            gl_FragColor = vec4(texColor.r, texColor.g, texColor.b, 1.0);
        }
    } else {
        gl_FragColor = vec4(texColor.r, texColor.g, texColor.b, 1.0);
    }
}