#version 300 es
/*
 * This shader only works with HTML5 target because Lime does not
 * support GLES3 on Windows or Mac. It should probably run on 
 * Linux but I've not tried it.
 *
 * Instancing is an ES3 feature.
 */
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 offset;

out vec3 fColor;

uniform vec2 offsets[100];

void main() {
    gl_Position = vec4(aPos + offset, 0.0, 1.0);
    fColor = aColor;
}