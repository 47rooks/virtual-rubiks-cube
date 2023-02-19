varying vec3 TexCoords;

uniform samplerCube skybox;

/* Render a fragment color from a cubemap */
void main()
{
    gl_FragColor = textureCube(skybox, TexCoords);
}