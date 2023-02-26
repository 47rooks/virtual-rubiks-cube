varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vTexCoords;

uniform samplerCube skybox;
uniform sampler2D openflDiffuseTex;

uniform vec3 cameraPos;
uniform bool reflection;
uniform bool refraction;

/* Render a fragment color environment mapping the surrounding skybox.
 * This shader supports reflection and refracton mappings.
 */
void main() {
    if (reflection) {
        vec3 I = normalize(vPosition - cameraPos);
        vec3 R = reflect(I, normalize(vNormal));
        // Use this gl_FragColor to see the effect of combining the cube texture with
        // reflection.
        // float alpha = 0.15;
        // vec4 color = texture2D(openflDiffuseTex, vTexCoords);
        // gl_FragColor = vec4((1 - alpha) * textureCube(skybox, R).rgb + alpha * color.rgb, 1.0);
        gl_FragColor = vec4(textureCube(skybox, R).rgb, 1.0);
    } else if (refraction) {
        float ratio = 1.00 / 1.52;
        vec3 I = normalize(vPosition - cameraPos);
        vec3 R = refract(I, normalize(vNormal), ratio);
        gl_FragColor = vec4(textureCube(skybox, R).rgb, 1.0);
    } else {
        gl_FragColor = texture2D(openflDiffuseTex, vTexCoords);
    }
}