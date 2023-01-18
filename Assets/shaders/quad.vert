/*
* Vertex shader for handling a basic quad, applying a model-view-projection matrix.
*/
attribute vec3 aPosition;
attribute vec2 aTexCoord;
attribute vec3 aNormal;
varying vec2 vTexCoord;

/* Full model-view-projection matrix */
uniform mat4 uMatrix;

void main(void)
{
    vTexCoord=aTexCoord;
    
    vec4 pos=vec4(aPosition,1.);
    gl_Position=uMatrix*pos;
}