package gl;

import MatrixUtils.matrix3DToFloat32Array;
import lights.PointLight;
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
 * The Outlining program outputs the same color to every fragment within the area of the model.
 * It is intended to be used with the stencil buffer to produce an outline effect.
 */
class OutliningProgram extends Program
{
	// Shader source
	var _vertexSource:String;
	var _fragmentSource:String;

	// GL variables
	/* Full model-view-projection matrix */
	private var _programMatrixUniform:GLUniformLocation;
	/* Model matrix */
	private var _programModelMatrixUniform:GLUniformLocation;
	/* Image uniform used for the case where the cube face displays an image */
	private var _programImageUniform:Int;
	/* Vertex attributes for vertex coordinates, texture, color and normals. */
	private var _programVertexAttribute:Int;
	private var _programTextureAttribute:Int;
	private var _programNormalAttribute:Int;

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 * @param context An OpenFL 3D render context
	 */
	public function new(gl:WebGLRenderContext, context:Context3D):Void
	{
		var vertexSource = Assets.getText("assets/shaders/modelLoading.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/singleColorShader.frag");

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
		_programMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");
		_programModelMatrixUniform = _gl.getUniformLocation(_glProgram, "uModel");
	}

	public function render(model:Matrix3D, projection:Matrix3D, lightDirection:Float32Array, cameraPosition:Float32Array, vbo:VertexBuffer3D,
			ibo:IndexBuffer3D, diffuseLightMapTexture:RectangleTexture, specularLightMapTexture:RectangleTexture, pointLights:Array<PointLight>,
			flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI):Void
	{
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(model));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(projection));

		// Apply GL calls to submit the cube data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, vbo, 0, FLOAT_3);
		_context.setVertexBufferAt(_programNormalAttribute, vbo, 3, FLOAT_3);
		_context.setVertexBufferAt(_programTextureAttribute, vbo, 6, FLOAT_2);

		_context.drawTriangles(ibo);
	}
}
