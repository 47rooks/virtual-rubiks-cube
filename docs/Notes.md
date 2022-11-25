# Using OpenFL to learn OpenGL

OpenFL has a render context Context3D which provides limited access to OpenGL operations. There are limited options for binding GLSL variables. There is greater support for AGAL shaders but if you want to use GLSL and if you want more control over GL rendering another approach is required. It is possible to access and use the GL render context from lime.

In addition, if you want to render 2D objects in the same display with the 3D this is possible. But if you are using the GL render context it is necessary to carefully perform certain tasks with each context. Failing to do that will result in access violations from the `stage.context3D`. This can happen if you add a Sprite to the 2D stage and use a lime GL render context for 3D object. 

This program uses two graphics context objects, the `stage.context3D`, a Context3D object which is used to render the vertex buffer, uploading textures, and to call drawTriangles() with the index buffer specifying which vertices to draw. The second context is the GL renderer context and this is used to gain more control of the GL rendering. It is used for setting uniforms, and controlling depth testing and all other GL features. Both contexts ultimately render through the GL renderer I believe. Using this approach renders both 2D and 3D content without problems.

With this basic setup then this program provides a vehicle for working through 'Learn OpenGL'.

## The Virtual Rubik's Cube (VRC)

The Rubik's cube provides very simple geometry that can be hardcoded in the program removing the need for a loader. It also works well with the initial two parts of Learn OpenGL. The VRC uses the WebGLRenderContext to do most of the GLSL interactions, and the Context3D for the texture upload and drawing operations. It uses HaxeUI for the 2D UI layer.

The `RubiksCube.hx` module creates multiple shader programs and depending upon the UI inputs it selects and uses the appropriate one.

## Index to Learn OpenGL

|Haxe Program|Vertex Shader|Fragment Shader|Learn OpenGL Refs|UI Options|
|-|-|-|-|-|
|SimpleCubeProgram|cube.vert|simplePhong.frag|8, 9, 10, 11, 12, 13|Simple lighting, Use Simple Texture|
|PhongMaterialsProgram|cube.vert|phongMaterials.frag|14|Use Phong Materials|
|LightMapsProgram|cube.vert|lightMaps.frag|15|3-component Phong lighting, Use Light Maps|