package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * The basic unit cube GLSL program, using Phong lighting, colours and a single texture.
 */
class PhongLightingProgram extends Program
{
	// Shader source
	var _vertexSource:String;
	var _fragmentSource:String;

	// GL variables
	private var _programMatrixUniform:GLUniformLocation;
	private var _programModelMatrixUniform:GLUniformLocation;
	private var _programTextureAttribute:Int;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	private var _programNormalAttribute:Int;
	private var _programLightColorUniform:GLUniformLocation;
	private var _programLightPositionUniform:GLUniformLocation;
	private var _programViewerPositionUniform:GLUniformLocation;
	private var _programAmbientStrengthUniform:GLUniformLocation;
	private var _programDiffuseStrengthUniform:GLUniformLocation;
	private var _programSpecularStrengthUniform:GLUniformLocation;
	private var _programSpecularIntensityUniform:GLUniformLocation;

	// Context3D variables
	private var _programImageUniform:GLUniformLocation;

	/**
	 * Constructor
	 * @param gl An WebGL render context
	 */
	public function new(gl:WebGL2RenderContext):Void
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/cube.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/simplePhong.frag");

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

		_programTextureAttribute = _gl.getAttribLocation(_glProgram, "aTexCoord");
		_gl.enableVertexAttribArray(_programTextureAttribute);

		_programColorAttribute = _gl.getAttribLocation(_glProgram, "aColor");
		_gl.enableVertexAttribArray(_programColorAttribute);

		_programNormalAttribute = _gl.getAttribLocation(_glProgram, "aNormal");
		_gl.enableVertexAttribArray(_programNormalAttribute);

		// Light
		_programLightColorUniform = _gl.getUniformLocation(_glProgram, "uLight");
		_programLightPositionUniform = _gl.getUniformLocation(_glProgram, "uLightPos");

		// Transformation matrices
		_programMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");
		_programModelMatrixUniform = _gl.getUniformLocation(_glProgram, "uModel");

		// Face texture
		_programImageUniform = _gl.getUniformLocation(_glProgram, "uImage0");

		// Phong Lighting
		_programAmbientStrengthUniform = _gl.getUniformLocation(_glProgram, "uAmbientStrength");
		_programDiffuseStrengthUniform = _gl.getUniformLocation(_glProgram, "uDiffuseStrength");
		_programSpecularStrengthUniform = _gl.getUniformLocation(_glProgram, "uSpecularStrength");
		_programSpecularIntensityUniform = _gl.getUniformLocation(_glProgram, "uSpecularIntensity");
		// Camera position - currently used for specular lighting
		_programViewerPositionUniform = _gl.getUniformLocation(_glProgram, "uViewerPos");
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

		// Light
		_gl.uniform3fv(_programLightColorUniform, params.lightColor, 0);
		_gl.uniform3fv(_programLightPositionUniform, params.lightPosition, 0);

		// Phong lighting
		_gl.uniform3fv(_programViewerPositionUniform, params.cameraPosition, 0);
		_gl.uniform1f(_programAmbientStrengthUniform, params.ui.ambientS);
		_gl.uniform1f(_programDiffuseStrengthUniform, params.ui.diffuseS);
		_gl.uniform1f(_programSpecularStrengthUniform, params.ui.specularS);
		_gl.uniform1f(_programSpecularIntensityUniform, params.ui.specularI);

		// Bind vertex buffer
		_gl.bindBuffer(_gl.ARRAY_BUFFER, params.vbo);

		// Setup attribute pointers
		var stride = 12 * Float32Array.BYTES_PER_ELEMENT;

		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, stride, 0);

		if (params.ui.textureEnabled)
		{
			_gl.enableVertexAttribArray(_programTextureAttribute);
			_gl.vertexAttribPointer(_programTextureAttribute, 2, _gl.FLOAT, false, stride, 3 * Float32Array.BYTES_PER_ELEMENT);
		}
		_gl.enableVertexAttribArray(_programColorAttribute);
		_gl.vertexAttribPointer(_programColorAttribute, 4, _gl.FLOAT, false, stride, 5 * Float32Array.BYTES_PER_ELEMENT);

		_gl.enableVertexAttribArray(_programNormalAttribute);

		_gl.vertexAttribPointer(_programNormalAttribute, 3, _gl.FLOAT, false, stride, 9 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);

		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
