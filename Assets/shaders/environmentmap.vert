#version 330

attribute vec3 aPos;
attribute vec3 aNormal;
attribute vec3 aTexCoords;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vTexCoords;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform bool reflection;
uniform bool refraction;

/*
 * This shader supports rendering a simple mesh passing normals to the
 * fragment shader so that it can implement environment mapping from
 * a skybox.
 */
void main() {
    if (reflection || refraction) {
        mat4 invModel = inverse(model);
        vNormal = mat3(transpose(invModel)) * aNormal;
        vPosition = vec3(model * vec4(aPos, 1.));
        /*
         * Normally one would have the model, the view and the projection 
         * matrices available. Here we have the model (in model uniform)
         * and the combined view-projection (in the projection uniform)
         * matrix. So this code differs from De Vries in that there is
         * no separate view matrix multiplication.
         */
        gl_Position = projection * vec4(aPos, 1.);
        vTexCoords = aTexCoords;
    } else {
        vTexCoords = aTexCoords;

        // Transform normals to world space to handle cube transformations.
        // Proper normal matrix not required as we only uniform scale
        // the cubes. If we did non-uniform we would need a normal matrix.
        vNormal = (model * vec4(aNormal, 0.)).xyz;

        vec4 pos = vec4(aPos, 1.);
        gl_Position = projection * pos;
        vPosition = (model * pos).xyz;
    }
}