/*
 * Simple Phong light shader which applies the same light parameters to each face regardless of
 * the material.
 */
varying vec2 vTexCoord;
varying vec4 vColor;
uniform sampler2D uImage0;

uniform vec3 uLightPos;   // Light position
uniform vec3 uLight;      // Light color
varying vec3 vNormal;     // Object normals
varying vec3 vFragPos;    // World position of fragment

uniform vec3 uViewerPos;   // Camera position

// Phong lighting parameters
uniform float uAmbientStrength;
uniform float uDiffuseStrength;
uniform float uSpecularStrength;
uniform float uSpecularIntensity;

void main(void)
{
    // Get the light's color
    vec3 lightColor = uLight.rgb / 255.0;

    /* Get the texture color */
    vec4 tColor = texture2D(uImage0, vTexCoord);
    vec3 cColor = tColor.rgb * vColor.rgb;
    if (tColor.a == 0.0) {
        cColor = vColor.rgb;
    }
    
    /* Compute diffuse lighting */
    vec3 norm = normalize(vNormal);
    vec3 lightDirection = normalize(uLightPos - vFragPos);
    float diffuse = max(dot(norm, lightDirection), 0.0) * uDiffuseStrength;

    /* Compute specular lighting */
    vec3 viewerDir = normalize(uViewerPos.xyz - vFragPos);
    vec3 reflectDir = reflect(-lightDirection, norm);
    float spec = pow(max(dot(viewerDir, reflectDir), 0.0), pow(2.0, uSpecularIntensity));
    vec3 specular = uSpecularStrength * spec * lightColor;

    /* Apply ambient, diffuse and specular lighting components */
    vec3 litColor = cColor * (uAmbientStrength + diffuse + specular);
    
    gl_FragColor = vec4(litColor, 1.0);
}
