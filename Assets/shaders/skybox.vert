attribute vec3 aPos;

varying vec3 TexCoords;

uniform mat4 projection;
uniform mat4 view;

void main()
{
    // Invert z-coord to compensate for the left-handed nature of the cubemap textures as
    // specified by RenderMan. Refer https://learnopengl.com/Advanced-OpenGL/Cubemaps and search
    // for RenderMan in the comments.
    TexCoords=vec3(aPos.xy,-aPos.z);
    vec4 pos=projection*view*vec4(aPos,1.);
    gl_Position=pos.xyww;
}