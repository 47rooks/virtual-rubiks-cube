package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * The blending program handles both the demonstration of simple background transparency and the more complex blending of multiple semi-transparent images.
 */
class BlendingProgram extends Program
{
	// GL variables
	// Projection matrix
	private var _programProjectionMatrixUniform:GLUniformLocation;

	/* Image uniform used for the case where the cube face displays an image */
	private var _programImageUniform:GLUniformLocation;

	/* Vertex attributes for vertex coordinates, texture, color and normals. */
	private var _programVertexAttribute:Int;
	private var _programTextureAttribute:Int;
	private var _programNormalAttribute:Int;

	// Alpha threshold under which to discard a fragment
	private var _programThresholdAlphaUniform:GLUniformLocation;
	private var _programAlphaThresholdValueUniform:GLUniformLocation;

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 */
	public function new(gl:WebGLRenderContext):Void
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/quad.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/quad.frag");

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

		// alpha threshold for discarding fragments
		_programThresholdAlphaUniform = _gl.getUniformLocation(_glProgram, "uThresholdAlpha");
		_programAlphaThresholdValueUniform = _gl.getUniformLocation(_glProgram, "uAlphaThresholdValue");

		_programImageUniform = _gl.getUniformLocation(_glProgram, "texture1");
	}

	public function render(params:ProgramParameters)
	{
		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programProjectionMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Image texture
		_gl.uniform1i(_programImageUniform, 0);
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);

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

		_gl.uniform1i(_programThresholdAlphaUniform, params.ui.blendThresholdAlpha ? 1 : 0);
		_gl.uniform1f(_programAlphaThresholdValueUniform, params.ui.blendAlphaValueThreshold);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);

		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
