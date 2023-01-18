package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import openfl.Assets;
import openfl.display3D.Context3D;

/**
 * The blending program handles both the demonstration of simple background transparency and the more complex blending of multiple semi-transparent images.
 */
class BlendingProgram extends Program
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

	// Alpha threshold under which to discard a fragment
	private var _programThresholdAlphaUniform:GLUniformLocation;
	private var _programAlphaThresholdValueUniform:GLUniformLocation;

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 * @param context An OpenFL 3D render context
	 */
	public function new(gl:WebGLRenderContext, context:Context3D):Void
	{
		var vertexSource = Assets.getText("assets/shaders/quad.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/quad.frag");

		super(gl, context);
		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

	public function getShaderVarLocations():Void
	{
		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPosition");
		_gl.enableVertexAttribArray(_programVertexAttribute);

		_programNormalAttribute = _gl.getAttribLocation(_glProgram, "aNormal");
		_gl.enableVertexAttribArray(_programNormalAttribute);

		_programTextureAttribute = _gl.getAttribLocation(_glProgram, "aTexCoord");
		_gl.enableVertexAttribArray(_programTextureAttribute);

		// Transformation matrices
		_programProjectionMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");

		// alpha threshold for discarding fragments
		_programThresholdAlphaUniform = _gl.getUniformLocation(_glProgram, "uThresholdAlpha");
		_programAlphaThresholdValueUniform = _gl.getUniformLocation(_glProgram, "uAlphaThresholdValue");
	}

	public function render(params:ProgramParameters)
	{
		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programProjectionMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Image texture
		_gl.uniform1i(_programImageUniform, 0);
		_context.setTextureAt(0, params.textures[0]);

		// Apply GL calls to submit the cube data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, params.vbo, 0, FLOAT_3);
		_context.setVertexBufferAt(_programNormalAttribute, params.vbo, 3, FLOAT_3);
		_context.setVertexBufferAt(_programTextureAttribute, params.vbo, 6, FLOAT_2);

		_gl.uniform1i(_programThresholdAlphaUniform, params.ui.blendThresholdAlpha ? 1 : 0);
		_gl.uniform1f(_programAlphaThresholdValueUniform, params.ui.blendAlphaValueThreshold);

		_context.drawTriangles(params.ibo);
	}
}
