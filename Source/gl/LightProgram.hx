package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import openfl.Assets;
import openfl.display3D.Context3D;

/**
 * GL program class for a simple light.
 */
class LightProgram extends Program
{
	// GL variables
	private var _programMatrixUniform:GLUniformLocation;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	// 3-component color
	private var _program3CompLightColorUniform:GLUniformLocation;
	private var _program3CompLightEnabledUniform:GLUniformLocation;

	// Shader source
	var _vertexSource:String;
	var _fragmentSource:String;

	/**
	 * Constructor
	 * @param gl An WebGL render context
	 * @param context The OpenFL 3D render context
	 */
	public function new(gl:WebGLRenderContext, context:Context3D):Void
	{
		var vertexSource = Assets.getText("assets/shaders/light.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/light.frag");

		super(gl, context);
		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

	/**
	 * Get all the GLSL variables locations and store
	 * them in member variables, so they can be bound to
	 * values during render().
	 */
	public function getShaderVarLocations():Void
	{
		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPosition");
		_gl.enableVertexAttribArray(_programVertexAttribute);

		_programColorAttribute = _gl.getAttribLocation(_glProgram, "aColor");
		_gl.enableVertexAttribArray(_programColorAttribute);

		// Transformation matrices
		_programMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");

		// Color variables
		_program3CompLightEnabledUniform = _gl.getUniformLocation(_glProgram, "u3CompLightEnabled");
		_program3CompLightColorUniform = _gl.getUniformLocation(_glProgram, "uLightColor");
	}

	/**
	 * Draw with the specified parameters.
	 * @param params the program parameters
	 * 	the following ProgramParameters fields are required
	 * 		- vbo
	 * 		- ibo
	 * 		- projectionMatrix
	 * 		- ui
	 */
	public function render(params:ProgramParameters):Void
	{
		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Set light color if selected
		_gl.uniform1i(_program3CompLightEnabledUniform, params.ui.componentLightEnabled ? 1 : 0);
		_gl.uniform3f(_program3CompLightColorUniform, params.ui.lightAmbientColor.r, params.ui.lightAmbientColor.g, params.ui.lightAmbientColor.b);

		// Apply GL calls to submit the cube data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, params.vbo, 0, FLOAT_3);
		_context.setVertexBufferAt(_programColorAttribute, params.vbo, 4, FLOAT_4);

		_context.drawTriangles(params.ibo);
	}
}
