#version 300 es
/*
 * This shader only works with HTML5 target because Lime does not
 * support GLES3 on Windows or Mac. It should probably run on 
 * Linux but I've not tried it.
 *
 * Strictly this shader could run elsewhere but the instancing
 * in the corresponding vert shader requires ES3.
 */
precision mediump float;

in vec3 fColor;
out vec4 FragColor;

void main() {
    FragColor = vec4(fColor, 1.0);
}