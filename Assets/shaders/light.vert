/*
* Vertex shader for basic light object applying matrix transformation.
*/
attribute vec3 aPosition;
attribute vec4 aColor;
varying vec4 vColor;

uniform mat4 uMatrix;

void main(void){
    
    vColor=aColor/vec4(0xff);
    gl_Position=uMatrix*vec4(aPosition,1.);
}