package gl;

import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import openfl.Assets;
import openfl.display3D.Context3D;

class PhongMaterialsProgram extends Program
{
	// Shader source
	var _vertexSource:String;
	var _fragmentSource:String;

	// GL variables
	private var _programImageUniform:GLUniformLocation;
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

	public function new(gl:WebGLRenderContext, context:Context3D):Void
	{
		var vertexSource = Assets.getText("assets/shaders/cube.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/phongMaterials.frag");

		super(gl, context);
		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

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
}
