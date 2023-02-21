# Using Lime to learn OpenGL

OpenFL has a render context Context3D which provides limited access to OpenGL operations. There are limited options for binding GLSL variables. There is greater support for AGAL shaders but if you want to use GLSL and if you want more control over GL rendering another approach is required. It is possible to access and use the GL render context from lime. So all this code uses the Lime WebGL2RenderContext to do OpenGL operations.

The UI is done in HaxeUI using the OpenFL backend. This means that there are two renderers in use.

With this basic setup then this program provides a vehicle for working through 'Learn OpenGL'.

## The Virtual Rubik's Cube (VRC)

The Rubik's cube provides very simple geometry that can be hardcoded in the program removing the need for a loader. It also works well with the initial two parts of Learn OpenGL. It uses HaxeUI for the 2D UI layer.

The `RubiksCube.hx` module creates multiple shader programs and depending upon the UI inputs it selects and uses the appropriate one.

## Index to Learn OpenGL

|Haxe Program|Vertex Shader|Fragment Shader|Learn OpenGL Refs|UI Options|
|-|-|-|-|-|
|SimpleCubeProgram|cube.vert|simplePhong.frag|8, 9, 10, 11, 12, 13|Simple lighting, Use Simple Texture|
|PhongMaterialsProgram|cube.vert|phongMaterials.frag|14|Use Phong Materials|
|LightMapsProgram|cube.vert|lightMaps.frag|15|3-component Phong lighting, Use Light Maps|