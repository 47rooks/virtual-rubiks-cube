package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

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
	 */
	public function new(gl:WebGLRenderContext):Void
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/light.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/light.frag");

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
		// Set up attribute pointers
		var stride = 7 * Float32Array.BYTES_PER_ELEMENT;
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, stride, 0);

		_gl.enableVertexAttribArray(_programColorAttribute);
		_gl.vertexAttribPointer(_programColorAttribute, 4, _gl.FLOAT, false, stride, 3 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		var indexBuffer = _gl.createBuffer();
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
		_gl.bufferData(_gl.ELEMENT_ARRAY_BUFFER, params.indexBufferData, _gl.STATIC_DRAW);

		_gl.drawElements(_gl.TRIANGLES, params.indexBufferData.length, _gl.UNSIGNED_INT, 0);
	}
}
