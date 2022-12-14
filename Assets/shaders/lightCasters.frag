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

struct Flashight {
    bool enabled;

    vec3 position;
    vec3 direction;
    float cutoff;

    // Light colors
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    // Attenuation values
    float constant;
    float linear;
    float quadratic;
};
uniform Flashight uFlashlight;

vec3 computeDiffuseContribution(vec3 diffuseLightColor, vec3 norm, vec3 lightDirection)
{
    float diff = max(dot(norm, lightDirection), 0.0);
    return diffuseLightColor * (diff *  vec3(texture2D(uMaterial.diffuse, vTexCoord)));
}

vec3 computeSpecularContribution(vec3 specularLightColor, vec3 norm, vec3 lightDirection)
{
        vec3 viewerDir = normalize(uViewerPos.xyz - vFragPos);
        vec3 reflectDir = reflect(-lightDirection, norm);
        float spec = pow(max(dot(viewerDir, reflectDir), 0.0), uMaterial.shininess);
        return specularLightColor * spec *vec3(texture2D(uMaterial.specular, vTexCoord));
}

void main(void)
{
    vec3 diffuse = vec3(0.0, 0.0, 0.0);
    vec3 specular = vec3(0.0, 0.0, 0.0);
    
    vec3 ambientLightColor = vec3(0.0, 0.0, 0.0);
    vec3 diffuseLightColor = vec3(0.0, 0.0, 0.0);
    vec3 specularLightColor = vec3(0.0, 0.0, 0.0);

    vec3 norm = normalize(vNormal);

    /* Compute directional light contribution */
    if (uDirectionalLight.enabled) {
        ambientLightColor = uDirectionalLight.ambient / 255.0;
        diffuseLightColor = uDirectionalLight.diffuse / 255.0;
        specularLightColor = uDirectionalLight.specular / 255.0;

        /* Compute diffuse material */
        vec3 lightDirection = normalize(-uDirectionalLight.direction);
        diffuse += computeDiffuseContribution(diffuseLightColor, norm, lightDirection);

        /* Compute specular material */
        specular += computeSpecularContribution(specularLightColor, norm, lightDirection);
    }

    /* Compute point light contribution */
    if (uPointLight.enabled) {
        float distance = length(uPointLight.position - vFragPos);
        float attenuation = 1.0 / (uPointLight.constant + (uPointLight.linear * distance) + (uPointLight.quadratic * distance * distance));

        ambientLightColor += uPointLight.ambient / 255.0 * attenuation;

        vec3 pointDiffuseLightColor = uPointLight.diffuse / 255.0 * attenuation;
        vec3 pointSpecularLightColor = uPointLight.specular / 255.0 * attenuation;

        /* Compute diffuse material */
        vec3 lightDirection = normalize(uPointLight.position - vFragPos);
        diffuse += computeDiffuseContribution(pointDiffuseLightColor, norm, lightDirection);

        /* Compute specular material */
        specular += computeSpecularContribution(pointSpecularLightColor, norm, lightDirection);
    }

    /* Compute flashlight contribution */
    if (uFlashlight.enabled) {
        // Compute theta to determine if fragment is lit by flashlight
        vec3 lightDirection = normalize(uFlashlight.position - vFragPos);
        float theta = dot(lightDirection, normalize(-uFlashlight.direction));
        if (theta > uFlashlight.cutoff) {
            float distance = length(uFlashlight.position - vFragPos);
            float attenuation = 1.0 / (uFlashlight.constant + (uFlashlight.linear * distance) + (uFlashlight.quadratic * distance * distance));

            ambientLightColor += uFlashlight.ambient / 255.0 * attenuation;

            vec3 flashDiffuseLightColor = uFlashlight.diffuse / 255.0 * attenuation;
            vec3 flashSpecularLightColor = uFlashlight.specular / 255.0 * attenuation;

            /* Compute diffuse material */
            diffuse += computeDiffuseContribution(flashDiffuseLightColor, norm, lightDirection);

            /* Compute specular material */
            specular += computeSpecularContribution(flashSpecularLightColor, norm, lightDirection);
        } else {
            ambientLightColor += uFlashlight.ambient / 255.0;
        }
    }

    /* Compute ambient material */
    vec3 ambient = ambientLightColor * vec3(texture2D(uMaterial.diffuse, vTexCoord));

    /* Apply ambient and diffuse lighting */
    vec3 litColor = ambient + diffuse + specular;
    
    gl_FragColor = vec4(litColor, 1.0);
}
