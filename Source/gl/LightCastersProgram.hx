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

/**
 * A program class supporting light casters.
 */
class LightCastersProgram extends Program
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
	private var _programColorAttribute:Int;
	private var _programNormalAttribute:Int;

	// Lighting variables
	/* Directional light variables */
	private var _programDirectionLightUniform:GLUniformLocation;
	private var _programAmbientLightUniform:GLUniformLocation;
	private var _programDiffuseLightUniform:GLUniformLocation;
	private var _programSpecularLightUniform:GLUniformLocation;

	/* Camera position for light calculations */
	private var _programViewerPositionUniform:GLUniformLocation;

	/* Material properties - lighting maps */
	private var _programDiffuseLightMapUniform:GLUniformLocation; // Diffuse light map
	private var _programSpecularLightMapUniform:GLUniformLocation; // Specular light map
	private var _programSpecularShininessUniform:GLUniformLocation; // Shininess

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 * @param context An OpenFL 3D render context
	 */
	public function new(gl:WebGLRenderContext, context:Context3D):Void
	{
		var vertexSource = Assets.getText("assets/shaders/cube.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/lightCasters.frag");

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
		_programDirectionLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.direction");
		_programAmbientLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.ambient");
		_programDiffuseLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.diffuse");
		_programSpecularLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.specular");

		// Transformation matrices
		_programMatrixUniform = _gl.getUniformLocation(_glProgram, "uMatrix");
		_programModelMatrixUniform = _gl.getUniformLocation(_glProgram, "uModel");

		// Light Maps
		_programDiffuseLightMapUniform = _gl.getUniformLocation(_glProgram, "uMaterial.diffuse");
		_programSpecularLightMapUniform = _gl.getUniformLocation(_glProgram, "uMaterial.specular");
		_programSpecularShininessUniform = _gl.getUniformLocation(_glProgram, "uMaterial.shininess");

		// Camera position - currently used for specular lighting
		_programViewerPositionUniform = _gl.getUniformLocation(_glProgram, "uViewerPos");
	}

	public function render(model:Matrix3D, projection:Matrix3D, lightColor:Float32Array, lightDirection:Float32Array, cameraPosition:Float32Array,
			vbo:VertexBuffer3D, ibo:IndexBuffer3D, diffuseLightMapTexture:RectangleTexture, specularLightMapTexture:RectangleTexture, ui:UI):Void
	{
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(model));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(projection));

		// Light
		_gl.uniform3fv(_programDirectionLightUniform, lightDirection, 0);
		_gl.uniform3f(_programAmbientLightUniform, ui.lightDirectionalAmbientColor.r, ui.lightDirectionalAmbientColor.g, ui.lightDirectionalAmbientColor.b);
		_gl.uniform3f(_programDiffuseLightUniform, ui.lightDirectionalDiffuseColor.r, ui.lightDirectionalDiffuseColor.g, ui.lightDirectionalDiffuseColor.b);
		_gl.uniform3f(_programSpecularLightUniform, ui.lightDirectionalSpecularColor.r, ui.lightDirectionalSpecularColor.g,
			ui.lightDirectionalSpecularColor.b);

		// Lighting maps
		_gl.uniform1i(_programDiffuseLightMapUniform, 0); // Diffuse lighting map
		_context.setTextureAt(0, diffuseLightMapTexture);
		_gl.uniform1i(_programSpecularLightMapUniform, 1); // Specular lighting map
		_context.setTextureAt(1, specularLightMapTexture);
		_gl.uniform3fv(_programViewerPositionUniform, cameraPosition, 0);
		_gl.uniform1f(_programSpecularShininessUniform, Math.pow(2, ui.specularShininess));

		// Apply GL calls to submit the cube data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, vbo, 0, FLOAT_3);
		_context.setVertexBufferAt(_programTextureAttribute, vbo, 3, FLOAT_2);
		_context.setVertexBufferAt(_programColorAttribute, vbo, 5, FLOAT_4);
		_context.setVertexBufferAt(_programNormalAttribute, vbo, 9, FLOAT_3);

		_context.drawTriangles(ibo);
	}
}