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
struct DirectionalLight {
    bool enabled;
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
uniform DirectionalLight uDirectionalLight;

struct PointLight {
    bool enabled;

    vec3 position;

    // Light colors
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    // Attenuation values
    float constant;
    float linear;
    float quadratic;
};
uniform PointLight uPointLight;

struct Flashlight {
    bool enabled;

    vec3 position;
    vec3 direction;
    float inner_cutoff;
    float outer_cutoff;

    // Light colors
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    // Attenuation values
    float constant;
    float linear;
    float quadratic;
};
uniform Flashlight uFlashlight;

/*
 * Compute the contribution of the directional light
 *
 * Parameters
 *   DirectionalLight light - the point light to compute contribution for
 *   vec3 normal - the normal to the fragment
 *   vec3 viewerDir - the direction to the viewer
 *
 * Returns
 *   vec3 color contribution of this light
 */
vec3 computeDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewerDir)
{
    vec3 lightDirection = normalize(-light.direction);
    // diffuse lighting
    float diff = max(dot(normal, lightDirection), 0.0);
    // specular lighting
    vec3 reflectDir = reflect(-lightDirection, normal);
    float spec = pow(max(dot(viewerDir, reflectDir), 0.0), uMaterial.shininess);

    // combine results
    vec3 ambient = light.ambient / 255.0 * vec3(texture2D(uMaterial.diffuse, vTexCoord));
    vec3 diffuse = light.diffuse / 255.0 * (diff *  vec3(texture2D(uMaterial.diffuse, vTexCoord)));
    vec3 specular = light.specular / 255.0 * spec * vec3(texture2D(uMaterial.specular, vTexCoord));

    return ambient + diffuse + specular;
}

/*
 * Compute the point light contribution
 *
 * Parameters
 *   PointLight light - the point light to compute contribution for
 *   vec3 normal - the normal to the fragment
 *   vec3 fragPos - the fragment position in world coordinates
 *   vec3 viewerDir - the direction to the viewer
 *
 * Returns
 *   vec3 color contribution of this light
 */
vec3 computePointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewerDir)
{
    vec3 lightDirection = normalize(light.position - fragPos);
    // diffuse lighting
    float diff = max(dot(normal, lightDirection), 0.0);
    // specular lighting
    vec3 reflectDir = reflect(-lightDirection, normal);
    float spec = pow(max(dot(viewerDir, reflectDir), 0.0), uMaterial.shininess);

    // Compute ttenuation factor
    float distance = length(light.position - vFragPos);
    float attenuation = 1.0 / (light.constant + (light.linear * distance) + (light.quadratic * distance * distance));

    // combine results
    vec3 ambient = light.ambient / 255.0 * vec3(texture2D(uMaterial.diffuse, vTexCoord));
    vec3 diffuse = light.diffuse / 255.0 * (diff *  vec3(texture2D(uMaterial.diffuse, vTexCoord)));
    vec3 specular = light.specular / 255.0 * spec * vec3(texture2D(uMaterial.specular, vTexCoord));

    // Apply attenuation
    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;

    return ambient + diffuse + specular;
}

/*
 * Compute spotlight contribution
 *
 * Parameters
 *   Flashlight light - the spotlight to compute contribution for
 *   vec3 normal - the normal to the fragment
 *   vec3 fragPos - the fragment position in world coordinates
 *   vec3 viewerDir - the direction to the viewer
 *
 * Returns
 *   vec3 color contribution of this light
 */
vec3 computeSpotLight(Flashlight light, vec3 normal, vec3 fragPos, vec3 viewerDir)
{
    // Compute theta to determine if fragment is lit by flashlight
    vec3 lightDirection = normalize(light.position - fragPos);

    // Light cone and intensity for soft edges
    float theta = dot(lightDirection, normalize(-light.direction));
    float epsilon = light.inner_cutoff - light.outer_cutoff;
    float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);

    // diffuse lighting
    float diff = max(dot(normal, lightDirection), 0.0);

    // specular lighting
    vec3 reflectDir = reflect(-lightDirection, normal);
    float spec = pow(max(dot(viewerDir, reflectDir), 0.0), uMaterial.shininess);

    vec3 ambient = vec3(0.0, 0.0, 0.0);
    vec3 diffuse = vec3(0.0, 0.0, 0.0);
    vec3 specular = vec3(0.0, 0.0, 0.0);

    if (theta > light.outer_cutoff) {
        // Calculate attenuation
        float distance = length(light.position - fragPos);
        float attenuation = 1.0 / (light.constant + (light.linear * distance) + (light.quadratic * distance * distance));

        // combine results
        ambient += light.ambient / 255.0 * vec3(texture2D(uMaterial.diffuse, vTexCoord));
        diffuse += intensity * light.diffuse / 255.0 * (diff *  vec3(texture2D(uMaterial.diffuse, vTexCoord)));
        specular += intensity * light.specular / 255.0 * spec * vec3(texture2D(uMaterial.specular, vTexCoord));

        // Apply attenuation
        diffuse *= attenuation;
        specular *= attenuation;
    } else {
        ambient += light.ambient / 255.0 * vec3(texture2D(uMaterial.diffuse, vTexCoord));
    }

    return ambient + diffuse + specular;
}

void main(void)
{
    vec3 diffuse = vec3(0.0, 0.0, 0.0);
    vec3 specular = vec3(0.0, 0.0, 0.0);
    
    vec3 ambientLightColor = vec3(0.0, 0.0, 0.0);
    vec3 diffuseLightColor = vec3(0.0, 0.0, 0.0);
    vec3 specularLightColor = vec3(0.0, 0.0, 0.0);

    vec3 outputColor = vec3 (0.0, 0.0, 0.0);

    vec3 viewerDir = normalize(uViewerPos.xyz - vFragPos);
    vec3 norm = normalize(vNormal);

    if (uDirectionalLight.enabled) {
        /* Compute directional light contribution */
        outputColor += computeDirectionalLight(uDirectionalLight, norm, viewerDir);
    }

    if (uPointLight.enabled) {
        /* Compute point light contribution */
        outputColor += computePointLight(uPointLight, norm, vFragPos, viewerDir);
    }

    if (uFlashlight.enabled) {
        /* Compute flashlight contribution */
        outputColor += computeSpotLight(uFlashlight, norm, vFragPos, viewerDir);
    }
    
    gl_FragColor = vec4(outputColor, 1.0);
}
