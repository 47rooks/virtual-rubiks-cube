/* 
 * Fragment shader supporting:
 *       Phong lighting
 *       Materials for the cube faces
 *       Light colors
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

// Materials
struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};
uniform Material uMaterial;

// Light colors
struct Light {
    bool enabled; // True if 3-component lighting is in use
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
uniform Light u3CompLight;

void main(void)
{
    /* Compute light color */
    vec3 lightColor = uLight.rgb / 255.0;
    vec3 ambientLightColor = lightColor;
    vec3 diffuseLightColor = lightColor;
    vec3 specularLightColor = lightColor;
    
    if (u3CompLight.enabled) {
        ambientLightColor = u3CompLight.ambient / 255.0;
        diffuseLightColor = u3CompLight.diffuse / 255.0;
        specularLightColor = u3CompLight.specular / 255.0;
    }

    /* Compute ambient material */
    vec3 ambient =  ambientLightColor * uMaterial.ambient / 255.0;

    /* Compute diffuse material */
    vec3 norm = normalize(vNormal);
    vec3 lightDirection = normalize(uLightPos - vFragPos);
    float diff = max(dot(norm, lightDirection), 0.0);
    vec3 diffuse = diffuseLightColor * (diff * uMaterial.diffuse / 255.0);

    /* Compute specular material */
    vec3 viewerDir = normalize(uViewerPos.xyz - vFragPos);
    vec3 reflectDir = reflect(-lightDirection, norm);
    float spec = pow(max(dot(viewerDir, reflectDir), 0.0), uMaterial.shininess);
    vec3 specular = uMaterial.specular / 255.0 * spec * specularLightColor;

    /* Apply ambient and diffuse lighting */
    // vec3 litColor = cColor * (uAmbientStrength + diffuse + specular);
    vec3 litColor = ambient + diffuse + specular;
    
    gl_FragColor = vec4(litColor, 1.0);
}
