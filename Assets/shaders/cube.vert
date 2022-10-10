attribute vec4 aPosition;
attribute vec2 aTexCoord;
varying vec2 vTexCoord;

attribute vec4 aColor;
varying vec4 vColor;

uniform mat4 uMatrix;

void main(void) {
    
    vTexCoord = aTexCoord;
    // Convert color from int (0-255) to float (0-1)
    vColor = aColor / vec4(0xff);
    gl_Position = uMatrix * aPosition;
}