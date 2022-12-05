/* 
 * Fragment shader supporting:
 *       Light casters
 *       Lighting maps cube faces
 *       Light colors
 */
varying vec2 vTexCoord;
varying vec4 vColor;

varying vec3 vNormal;     // Object normals
varying vec3 vFragPos;    // World position of fragment

uniform vec3 uViewerPos;   // Camera position

// Materials
struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float     shininess;
};
uniform Material uMaterial;

// Light colors
struct Light {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
uniform Light uDirectionalLight;

void main(void)
{
    /* Compute light color */
    vec3 ambientLightColor = uDirectionalLight.ambient / 255.0;
    vec3 diffuseLightColor = uDirectionalLight.diffuse / 255.0;
    vec3 specularLightColor = uDirectionalLight.specular / 255.0;

    /* Compute ambient material */
    vec3 ambient = ambientLightColor * vec3(texture2D(uMaterial.diffuse, vTexCoord));

    /* Compute diffuse material */
    vec3 norm = normalize(vNormal);
    vec3 lightDirection = normalize(-uDirectionalLight.direction);
    float diff = max(dot(norm, lightDirection), 0.0);
    vec3 diffuse = diffuseLightColor * (diff *  vec3(texture2D(uMaterial.diffuse, vTexCoord)));

    /* Compute specular material */
    vec3 viewerDir = normalize(uViewerPos.xyz - vFragPos);
    vec3 reflectDir = reflect(-lightDirection, norm);
    float spec = pow(max(dot(viewerDir, reflectDir), 0.0), uMaterial.shininess);
    vec3 specular = specularLightColor * spec *vec3(texture2D(uMaterial.specular, vTexCoord));

    /* Apply ambient and diffuse lighting */
    vec3 litColor = ambient + diffuse + specular;
    
    gl_FragColor = vec4(litColor, 1.0);
}
