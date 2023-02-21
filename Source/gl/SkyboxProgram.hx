package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * This program renders a skybox.
 */
class SkyboxProgram extends Program
{
	// GL variables
	// Projection matrix
	private var _programProjectionMatrixUniform:GLUniformLocation;
	// View matrix
	private var _programModelMatrixUniform:GLUniformLocation;

	/* Image uniform used for the case where the cube face displays an image */
	private var _programTextureUniform:GLUniformLocation;

	/* Vertex attributes for vertex coordinates, texture, color and normals. */
	private var _programVertexAttribute:Int;

	public function new(gl:WebGL2RenderContext)
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/skybox.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/skybox.frag");

		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

	public function getShaderVarLocations():Void
	{
		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPos");

		_programProjectionMatrixUniform = _gl.getUniformLocation(_glProgram, "projection");

		_programModelMatrixUniform = _gl.getUniformLocation(_glProgram, "view");

		// Texture uniform
		_programTextureUniform = _gl.getUniformLocation(_glProgram, "skybox");
	}

	public function render(params:ProgramParameters)
	{
		// Bind cubemap texture
		// trace('text=${params.textures[0]}');
		_gl.uniform1i(_programTextureUniform, 0);
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_CUBE_MAP, params.textures[0]);
		// _gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);
		_gl.activeTexture(0);

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programProjectionMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Add view and pass in to shader
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(params.modelMatrix));

		// Bind vertex buffer
		_gl.bindBuffer(_gl.ARRAY_BUFFER, params.vbo);

		// Set up attribute pointers
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 0);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);
		// trace('numI=${params.numIndexes}');
		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
