attribute vec3 aPos;

varying vec3 TexCoords;

uniform mat4 projection;
uniform mat4 view;

void main() {
    /* OpenGL uses the cubmap textures specified by RenderMan.
     * In order to compensate for the left-handed nature of the cubemap textures one
     * can invert the z-coord.
     * Refer https://learnopengl.com/Advanced-OpenGL/Cubemaps and search
     * for RenderMan in the comments.
     * However if you do so it impacts the environment examples. For example in the 
     * reflection example, if you invert the z-coord, it will appear to show you
     * through the cube rather than a reflection of what is behind the viewer/camera.
     *
     * Leaving the code below so that a -aPos.z can be substituted easily to see
     * the effect, but without the inversion so that the environment mapping
     * works as intended.
     */
    TexCoords = vec3(aPos.xy, aPos.z);
    vec4 pos = projection * view * vec4(aPos, 1.);
    gl_Position = pos.xyww;
}