/*
* Vertex shader for handling basic cube applying matrix transformation.
*/
attribute vec4 aPosition;
attribute vec2 aTexCoord;
varying vec2 vTexCoord;

attribute vec4 aColor;
varying vec4 vColor;

attribute vec3 aNormal;
varying vec3 vNormal;

varying vec3 vFragPos;

uniform mat4 uMatrix;
uniform mat4 uModel;

void main(void)
{
    vTexCoord=aTexCoord;
    vColor=aColor/vec4(0xff);
    
    // Transform normals to world space to handle cube transformations.
    // Proper normal matrix not required as we only uniform scale
    // the cubes. If we did non-uniform we would need a normal matrix.
    vNormal=(uModel*vec4(aNormal,0.)).xyz;
    
    gl_Position=uMatrix*aPosition;
    vFragPos=(uModel*aPosition).xyz;
}