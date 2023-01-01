/*
* Vertex shader for rendering a mesh applying matrix transformation.
*/
attribute vec3 aPosition;
attribute vec3 aNormal;
attribute vec2 aTexCoord;

varying vec2 vTexCoord;
varying vec3 vNormal;

/* Fragment position in world coordinates. Used for lighting calculations in the fragment shader. */
varying vec3 vFragPos;

/* Full model-view-projection matrix */
uniform mat4 uMatrix;

/* Model matrix - used to pass the world space position of a fragment
* to the fragment shader for lighting calculations.
*/
uniform mat4 uModel;

void main(void)
{
    vTexCoord=aTexCoord;
    
    // Transform normals to world space to handle cube transformations.
    // Proper normal matrix not required as we only uniform scale
    // the cubes. If we did non-uniform we would need a normal matrix.
    vNormal=(uModel*vec4(aNormal,0.)).xyz;
    
    vec4 pos=vec4(aPosition,1.);
    gl_Position=uMatrix*pos;
    vFragPos=(uModel*pos).xyz;
}