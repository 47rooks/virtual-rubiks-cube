package gl;

import MatrixUtils.matrix3DToFloat32Array;
import gl.Program.ProgramParameters;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * A program class supporting lighting maps.
 */
class LightMapsProgram extends Program
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
	/* Light position */
	private var _programLightPositionUniform:GLUniformLocation;
	/* Simple single color light color */
	private var _programLightColorUniform:GLUniformLocation;
	/* 3-component light enabled and color variables */
	private var _programEnabledLightUniform:GLUniformLocation;
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
	 */
	public function new(gl:WebGL2RenderContext):Void
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/cube.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/lightMaps.frag");

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
		_programEnabledLightUniform = _gl.getUniformLocation(_glProgram, "u3CompLight.enabled");
		_programAmbientLightUniform = _gl.getUniformLocation(_glProgram, "u3CompLight.ambient");
		_programDiffuseLightUniform = _gl.getUniformLocation(_glProgram, "u3CompLight.diffuse");
		_programSpecularLightUniform = _gl.getUniformLocation(_glProgram, "u3CompLight.specular");

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

	/**
	 * Draw with the specified parameters.
	 * @param params the program parameters. The following ProgramParameters fields are required:
	 * 		- vbo
	 * 		- ibo
	 * 		- textures
	 * 			- 0 the diffuse light map
	 * 			- 1 the specular light map
	 * 		- modelMatrix
	 * 		- projectionMatrix
	 * 		- lightColor
	 * 		- lightPosition
	 * 		- cameraPosition
	 * 		- ui
	 */
	public function render(params:ProgramParameters):Void
	{
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(params.modelMatrix));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Light
		_gl.uniform3fv(_programLightColorUniform, params.lightColor, 0);
		_gl.uniform3fv(_programLightPositionUniform, params.lightPosition, 0);

		_gl.uniform1i(_programEnabledLightUniform, params.ui.componentLightEnabled ? 1 : 0);
		_gl.uniform3f(_programAmbientLightUniform, params.ui.lightAmbientColor.r, params.ui.lightAmbientColor.g, params.ui.lightAmbientColor.b);
		_gl.uniform3f(_programDiffuseLightUniform, params.ui.lightDiffuseColor.r, params.ui.lightDiffuseColor.g, params.ui.lightDiffuseColor.b);
		_gl.uniform3f(_programSpecularLightUniform, params.ui.lightSpecularColor.r, params.ui.lightSpecularColor.g, params.ui.lightSpecularColor.b);

		// Lighting maps
		_gl.uniform1i(_programDiffuseLightMapUniform, 0); // Diffuse lighting map
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);
		_gl.uniform1i(_programSpecularLightMapUniform, 1); // Specular lighting map
		_gl.activeTexture(_gl.TEXTURE1);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[1]);
		_gl.activeTexture(0);

		_gl.uniform3fv(_programViewerPositionUniform, params.cameraPosition, 0);
		_gl.uniform1f(_programSpecularShininessUniform, Math.pow(2, params.ui.specularShininess));

		// Bind vertex buffer
		_gl.bindBuffer(_gl.ARRAY_BUFFER, params.vbo);

		// Set up attribute pointers
		var stride = 12 * Float32Array.BYTES_PER_ELEMENT;
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 3, _gl.FLOAT, false, stride, 0);

		_gl.enableVertexAttribArray(_programTextureAttribute);
		_gl.vertexAttribPointer(_programTextureAttribute, 2, _gl.FLOAT, false, stride, 3 * Float32Array.BYTES_PER_ELEMENT);

		_gl.enableVertexAttribArray(_programColorAttribute);
		_gl.vertexAttribPointer(_programColorAttribute, 4, _gl.FLOAT, false, stride, 5 * Float32Array.BYTES_PER_ELEMENT);

		_gl.enableVertexAttribArray(_programNormalAttribute);
		_gl.vertexAttribPointer(_programNormalAttribute, 3, _gl.FLOAT, false, stride, 9 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);

		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
