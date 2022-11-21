package gl;

import MatrixUtils.matrix3DToFloat32Array;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import openfl.Assets;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix3D;

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
	 * Render the cube with the specified parameters.
	 * @param model the model matrix
	 * @param projection the final model-view-projection matrix
	 * @param vbo the vertext buffer
	 * @param ibo the index buffer for indexed drawing
	 * @param ui the properties object from the UI
	 */
	public function render(model:Matrix3D, projection:Matrix3D, vbo:VertexBuffer3D, ibo:IndexBuffer3D, ui:UI):Void
	{
		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(projection));

		// Set light color if selected
		_gl.uniform1i(_program3CompLightEnabledUniform, ui.componentLightEnabled ? 1 : 0);
		_gl.uniform3f(_program3CompLightColorUniform, ui.lightAmbientColor.r, ui.lightAmbientColor.g, ui.lightAmbientColor.b);

		// Apply GL calls to submit the cube data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, vbo, 0, FLOAT_3);
		_context.setVertexBufferAt(_programColorAttribute, vbo, 4, FLOAT_4);

		_context.drawTriangles(ibo);
	}
}
