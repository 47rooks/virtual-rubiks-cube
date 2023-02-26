package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * CubemapProgram provides a simpler program to draw a cube built on a mesh, and supports
 * environment mapping of a skybox. The skybox cubemap texture must be bound to TEXTURE1
 * before calling render() method.
 */
class EnvironmentmapProgram extends Program
{
	var _programVertexAttribute:Int;
	var _programNormalAttribute:Int;
	var _programTextureAttribute:Int;

	var _cubeFaceDiffuseTexture:GLUniformLocation;
	var _skyboxTexture:GLUniformLocation;

	var _cameraPos:GLUniformLocation;
	var _model:GLUniformLocation;
	var _view:GLUniformLocation;
	var _projection:GLUniformLocation;

	var _reflection:GLUniformLocation;
	var _refraction:GLUniformLocation;

	/**
	 * Constructor
	 * @param gl Lime WebGL render context.
	 */
	public function new(gl:WebGL2RenderContext)
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/environmentmap.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/environmentmap.frag");

		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

	public function getShaderVarLocations():Void
	{
		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPos");
		_gl.enableVertexAttribArray(_programVertexAttribute);

		_programNormalAttribute = _gl.getAttribLocation(_glProgram, "aNormal");
		_gl.enableVertexAttribArray(_programNormalAttribute);

		_programTextureAttribute = _gl.getAttribLocation(_glProgram, "aTexCoords");
		_gl.enableVertexAttribArray(_programTextureAttribute);

		_cubeFaceDiffuseTexture = _gl.getUniformLocation(_glProgram, "openflDiffuseTex");
		_skyboxTexture = _gl.getUniformLocation(_glProgram, "skybox");

		_reflection = _gl.getUniformLocation(_glProgram, "reflection");
		_refraction = _gl.getUniformLocation(_glProgram, "refraction");

		_cameraPos = _gl.getUniformLocation(_glProgram, "cameraPos");

		_model = _gl.getUniformLocation(_glProgram, "model");
		_view = _gl.getUniformLocation(_glProgram, "view");
		_projection = _gl.getUniformLocation(_glProgram, "projection");
	}

	public function render(params:ProgramParameters)
	{
		_gl.uniformMatrix4fv(_model, false, matrix3DToFloat32Array(params.modelMatrix));

		// _gl.uniformMatrix4fv(_view, false, matrix3DToFloat32Array(params.viewMatrix));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_projection, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Camera (viewer) position
		_gl.uniform3fv(_cameraPos, params.cameraPosition, 0);

		// Environment mapping
		_gl.uniform1i(_reflection, params.ui.cubemapReflection ? 1 : 0);
		_gl.uniform1i(_refraction, params.ui.cubemapRefraction ? 1 : 0);

		// Textures
		_gl.uniform1i(_cubeFaceDiffuseTexture, 0);
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);

		// Caller must have bound the skybox texture to TEXTURE2.
		_gl.uniform1i(_skyboxTexture, 1);
		_gl.activeTexture(0);

		// Bind vertex buffer
		_gl.bindBuffer(_gl.ARRAY_BUFFER, params.vbo);

		// Set up attribute pointers
		var stride = 8 * Float32Array.BYTES_PER_ELEMENT;
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, stride, 0);

		_gl.enableVertexAttribArray(_programNormalAttribute);
		_gl.vertexAttribPointer(_programNormalAttribute, 3, _gl.FLOAT, false, stride, 3 * Float32Array.BYTES_PER_ELEMENT);

		_gl.enableVertexAttribArray(_programTextureAttribute);
		_gl.vertexAttribPointer(_programTextureAttribute, 2, _gl.FLOAT, false, stride, 6 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);

		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
