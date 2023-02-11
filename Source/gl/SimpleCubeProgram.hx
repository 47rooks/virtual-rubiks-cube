package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * The basic unit cube GLSL program rendering colours and a single texture.
 */
class SimpleCubeProgram extends Program
{
	// Shader source
	var _vertexSource:String;
	var _fragmentSource:String;

	// GL variables
	private var _vertexBuffer:GLBuffer;
	private var _indexBuffer:GLBuffer;
	private var _programMatrixUniform:GLUniformLocation;
	private var _programModelMatrixUniform:GLUniformLocation;
	private var _programTextureAttribute:Int;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;

	// Context3D variables
	private var _programImageUniform:Int;

	/**
	 * Constructor
	 * @param gl An WebGL render context
	 */
	public function new(gl:WebGLRenderContext):Void
	{
		var vertexSource = Assets.getText("assets/shaders/cube.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/cube.frag");

		super(gl);
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
		_vertexBuffer = _gl.createBuffer();
		_indexBuffer = _gl.createBuffer();

		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPosition");
		_gl.enableVertexAttribArray(_programVertexAttribute);

		_programTextureAttribute = _gl.getAttribLocation(_glProgram, "aTexCoord");
		_gl.enableVertexAttribArray(_programTextureAttribute);

		_programColorAttribute = _gl.getAttribLocation(_glProgram, "aColor");
		_gl.enableVertexAttribArray(_programColorAttribute);

		// Transformation matrices
		_programMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");
		_programModelMatrixUniform = _gl.getUniformLocation(_glProgram, "uModel");

		// Face texture
		_programImageUniform = _gl.getUniformLocation(_glProgram, "uImage0"); // "uImage0" uniform but Context3D just uses ints
	}

	/**
	 * Draw with the specified parameters.
	 * @param params the program parameters
	 * 	the following ProgramParameters fields are required
	 * 		- vbo
	 * 		- ibo
	 * 		- textures
	 * 			- 0 the model texture
	 * 		- modelMatrix
	 * 		- projectionMatrix
	 *		- cameraPosition
	 * 		- ui
	 */
	public function render(params:ProgramParameters):Void
	{
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(params.modelMatrix));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Image texture
		_gl.uniform1i(_programImageUniform, 0);
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);

		// Bind vertex buffer
		var vertexBuffer = _gl.createBuffer();
		_gl.bindBuffer(_gl.ARRAY_BUFFER, vertexBuffer);
		_gl.bufferData(_gl.ARRAY_BUFFER, params.vertexBufferData, _gl.STATIC_DRAW);

		// Set up attribute pointers
		var stride = 12 * Float32Array.BYTES_PER_ELEMENT;
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, stride, 0);

		_gl.enableVertexAttribArray(_programTextureAttribute);
		_gl.vertexAttribPointer(_programTextureAttribute, 2, _gl.FLOAT, false, stride, 3 * Float32Array.BYTES_PER_ELEMENT);

		_gl.enableVertexAttribArray(_programColorAttribute);
		_gl.vertexAttribPointer(_programColorAttribute, 4, _gl.FLOAT, false, stride, 5 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		var indexBuffer = _gl.createBuffer();
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
		_gl.bufferData(_gl.ELEMENT_ARRAY_BUFFER, params.indexBufferData, _gl.STATIC_DRAW);

		_gl.drawElements(_gl.TRIANGLES, params.indexBufferData.length, _gl.UNSIGNED_INT, 0);
	}
}
