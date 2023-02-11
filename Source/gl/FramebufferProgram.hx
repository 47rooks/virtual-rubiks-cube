package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * The framebuffer program demonstrates the use of a framebuffer for render the scene to a texture and applying post-processing effects to it.
 */
class FramebufferProgram extends Program
{
	// GL variables
	// Projection matrix
	private var _programProjectionMatrixUniform:GLUniformLocation;

	/* Image uniform used for the case where the cube face displays an image */
	private var _programImageUniform:Int;

	/* Vertex attributes for vertex coordinates, texture, color and normals. */
	private var _programVertexAttribute:Int;
	private var _programTextureAttribute:Int;
	private var _programNormalAttribute:Int;

	/* Postprocessing Effects */
	private var _programInversionEffectUniform:GLUniformLocation;
	private var _programGrayscaleEffectUniform:GLUniformLocation;

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 */
	public function new(gl:WebGLRenderContext):Void
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/quad.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/framebuffer.frag");

		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

	public function getShaderVarLocations():Void
	{
		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPosition");

		_programNormalAttribute = _gl.getAttribLocation(_glProgram, "aNormal");

		_programTextureAttribute = _gl.getAttribLocation(_glProgram, "aTexCoord");

		// Transformation matrices
		_programProjectionMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");

		// Texture uniform
		_programImageUniform = _gl.getUniformLocation(_glProgram, "texture1");

		// Postprocessing effects
		_programInversionEffectUniform = _gl.getUniformLocation(_glProgram, "uInversion");
		_programGrayscaleEffectUniform = _gl.getUniformLocation(_glProgram, "uGrayscale");
	}

	public function render(params:ProgramParameters)
	{
		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programProjectionMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// // Image texture
		_gl.uniform1i(_programImageUniform, 0);
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);

		// Bind vertex buffer
		_gl.bindBuffer(_gl.ARRAY_BUFFER, params.vbo);

		// Set up attribute pointers
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 0);

		_gl.enableVertexAttribArray(_programNormalAttribute);
		_gl.vertexAttribPointer(_programNormalAttribute, 3, _gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);

		_gl.enableVertexAttribArray(_programTextureAttribute);
		_gl.vertexAttribPointer(_programTextureAttribute, 2, _gl.FLOAT, false, 8 * Float32Array.BYTES_PER_ELEMENT, 6 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);

		// Postprocessing variables
		_gl.uniform1i(_programInversionEffectUniform, params.ui.uiInversion.selected ? 1 : 0);
		_gl.uniform1i(_programGrayscaleEffectUniform, params.ui.uiGrayscale.selected ? 1 : 0);

		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
