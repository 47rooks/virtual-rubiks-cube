package gl;

import MatrixUtils.matrix3DToFloat32Array;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Float32Array;
import openfl.Assets;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Matrix3D;
import ui.UI;

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
	private var _programImageUniform:Int;

	/**
	 * Constructor
	 * @param gl An WebGL render context
	 * @param context The OpenFL 3D render context
	 */
	public function new(gl:WebGLRenderContext, context:Context3D):Void
	{
		var vertexSource = Assets.getText("assets/shaders/cube.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/simplePhong.frag");

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
		_programImageUniform = 0; // "uImage0" uniform but Context3D just uses ints

		// Phong Lighting
		_programAmbientStrengthUniform = _gl.getUniformLocation(_glProgram, "uAmbientStrength");
		_programDiffuseStrengthUniform = _gl.getUniformLocation(_glProgram, "uDiffuseStrength");
		_programSpecularStrengthUniform = _gl.getUniformLocation(_glProgram, "uSpecularStrength");
		_programSpecularIntensityUniform = _gl.getUniformLocation(_glProgram, "uSpecularIntensity");
		// Camera position - currently used for specular lighting
		_programViewerPositionUniform = _gl.getUniformLocation(_glProgram, "uViewerPos");
	}

	/**
	 * Render the cube with the specified parameters.
	 * @param model the model matrix
	 * @param projection the final model-view-projection matrix
	 * @param lightColor the color of the light
	 * @param lightPosition the world position of the light
	 * @param cameraPosition the world position of the camera
	 * @param vbo the vertext buffer
	 * @param ibo the index buffer for indexed drawing
	 * @param texture the texture for the faces
	 * @param ui the properties object from the UI
	 */
	public function render(model:Matrix3D, projection:Matrix3D, lightColor:Float32Array, lightPosition:Float32Array, cameraPosition:Float32Array,
			vbo:VertexBuffer3D, ibo:IndexBuffer3D, texture:RectangleTexture, ui:UI):Void
	{
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(model));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(projection));

		// Image texture
		_context.setTextureAt(_programImageUniform, texture);

		// Light
		_gl.uniform3fv(_programLightColorUniform, lightColor, 0);
		_gl.uniform3fv(_programLightPositionUniform, lightPosition, 0);

		// Phong lighting
		_gl.uniform3fv(_programViewerPositionUniform, cameraPosition, 0);
		_gl.uniform1f(_programAmbientStrengthUniform, ui.ambientS);
		_gl.uniform1f(_programDiffuseStrengthUniform, ui.diffuseS);
		_gl.uniform1f(_programSpecularStrengthUniform, ui.specularS);
		_gl.uniform1f(_programSpecularIntensityUniform, ui.specularI);

		// Apply GL calls to submit the cubbe data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, vbo, 0, FLOAT_3);
		if (ui.textureEnabled)
		{
			_context.setVertexBufferAt(_programTextureAttribute, vbo, 3, FLOAT_2);
		}
		_context.setVertexBufferAt(_programColorAttribute, vbo, 5, FLOAT_4);
		_context.setVertexBufferAt(_programNormalAttribute, vbo, 9, FLOAT_3);

		_context.drawTriangles(ibo);
	}
}
