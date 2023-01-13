package gl;

import MatrixUtils.matrix3DToFloat32Array;
import MatrixUtils.radians;
import gl.Program.ProgramParameters;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLUniformLocation;
import openfl.Assets;
import openfl.display3D.Context3D;
import scenes.BasicsScene;

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
	private var _programEnabledLightUniform:GLUniformLocation;
	private var _programDirectionLightUniform:GLUniformLocation;
	private var _programAmbientLightUniform:GLUniformLocation;
	private var _programDiffuseLightUniform:GLUniformLocation;
	private var _programSpecularLightUniform:GLUniformLocation;

	/* Point light variables */
	private var _programPointLightEnabledUniform:Array<GLUniformLocation>;
	private var _programPointLightPositionUniform:Array<GLUniformLocation>;
	private var _programPointLightAmbientUniform:Array<GLUniformLocation>;
	private var _programPointLightDiffuseUniform:Array<GLUniformLocation>;
	private var _programPointLightSpecularUniform:Array<GLUniformLocation>;
	private var _programPointLightAttenuationKc:Array<GLUniformLocation>;
	private var _programPointLightAttenuationKl:Array<GLUniformLocation>;
	private var _programPointLightAttenuationKq:Array<GLUniformLocation>;

	// Flashlight variables
	private var _programFlashlightEnabledUniform:GLUniformLocation;
	private var _programFlashlightPositionUniform:GLUniformLocation;
	private var _programFlashlightDirectionUniform:GLUniformLocation;
	private var _programFlashlightInnerCutoffUniform:GLUniformLocation;
	private var _programFlashlightOuterCutoffUniform:GLUniformLocation;
	private var _programFlashlightAmbientUniform:GLUniformLocation;
	private var _programFlashlightDiffuseUniform:GLUniformLocation;
	private var _programFlashlightSpecularUniform:GLUniformLocation;
	private var _programFlashlightAttenuationKc:GLUniformLocation;
	private var _programFlashlightAttenuationKl:GLUniformLocation;
	private var _programFlashlightAttenuationKq:GLUniformLocation;

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

		// Directional light
		_programEnabledLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.enabled");
		_programDirectionLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.direction");
		_programAmbientLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.ambient");
		_programDiffuseLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.diffuse");
		_programSpecularLightUniform = _gl.getUniformLocation(_glProgram, "uDirectionalLight.specular");

		// Point lights
		_programPointLightEnabledUniform = new Array<GLUniformLocation>();
		_programPointLightPositionUniform = new Array<GLUniformLocation>();
		_programPointLightAmbientUniform = new Array<GLUniformLocation>();
		_programPointLightDiffuseUniform = new Array<GLUniformLocation>();
		_programPointLightSpecularUniform = new Array<GLUniformLocation>();
		_programPointLightAttenuationKc = new Array<GLUniformLocation>();
		_programPointLightAttenuationKl = new Array<GLUniformLocation>();
		_programPointLightAttenuationKq = new Array<GLUniformLocation>();

		for (i in 0...BasicsScene.NUM_POINT_LIGHTS)
		{
			_programPointLightEnabledUniform[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].enabled');
			_programPointLightPositionUniform[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].position');
			_programPointLightAmbientUniform[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].ambient');
			_programPointLightDiffuseUniform[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].diffuse');
			_programPointLightSpecularUniform[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].specular');
			_programPointLightAttenuationKc[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].constant');
			_programPointLightAttenuationKl[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].linear');
			_programPointLightAttenuationKq[i] = _gl.getUniformLocation(_glProgram, 'uPointLights[${i}].quadratic');
		}

		// Flashlight
		_programFlashlightEnabledUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.enabled");
		_programFlashlightPositionUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.position");
		_programFlashlightDirectionUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.direction");
		_programFlashlightInnerCutoffUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.inner_cutoff");
		_programFlashlightOuterCutoffUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.outer_cutoff");
		_programFlashlightAmbientUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.ambient");
		_programFlashlightDiffuseUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.diffuse");
		_programFlashlightSpecularUniform = _gl.getUniformLocation(_glProgram, "uFlashlight.specular");
		_programFlashlightAttenuationKc = _gl.getUniformLocation(_glProgram, "uFlashlight.constant");
		_programFlashlightAttenuationKl = _gl.getUniformLocation(_glProgram, "uFlashlight.linear");
		_programFlashlightAttenuationKq = _gl.getUniformLocation(_glProgram, "uFlashlight.quadratic");

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
	 * @param params the program parameters
	 * 	the following ProgramParameters fields are required
	 * 		- vbo
	 * 		- ibo
	 * 		- textures
	 * 			- 0 the diffuse light map
	 * 			- 1 the specular light map
	 * 		- modelMatrix
	 * 		- projectionMatrix
	 *		- cameraPosition
	 * 		- directionalLight
	 * 		- pointLights
	 * 		- flashlightPos
	 * 		- flashlightDir
	 * 		- ui
	 */
	public function render(params:ProgramParameters):Void
	{
		_gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(params.modelMatrix));

		// Add projection and pass in to shader
		_gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(params.projectionMatrix));

		// Directional light
		_gl.uniform1i(_programEnabledLightUniform, params.ui.directional ? 1 : 0);
		if (params.ui.directional)
		{
			_gl.uniform3fv(_programDirectionLightUniform, params.directionalLight, 0);
			_gl.uniform3f(_programAmbientLightUniform, params.ui.lightDirectionalAmbientColor.r, params.ui.lightDirectionalAmbientColor.g,
				params.ui.lightDirectionalAmbientColor.b);
			_gl.uniform3f(_programDiffuseLightUniform, params.ui.lightDirectionalDiffuseColor.r, params.ui.lightDirectionalDiffuseColor.g,
				params.ui.lightDirectionalDiffuseColor.b);
			_gl.uniform3f(_programSpecularLightUniform, params.ui.lightDirectionalSpecularColor.r, params.ui.lightDirectionalSpecularColor.g,
				params.ui.lightDirectionalSpecularColor.b);
		}

		// Point lights

		// Point light 1
		for (i in 0...BasicsScene.NUM_POINT_LIGHTS)
		{
			_gl.uniform1i(_programPointLightEnabledUniform[i], params.ui.pointLight(i).uiPointLightEnabled.selected ? 1 : 0);
			if (params.ui.pointLight(i).uiPointLightEnabled.selected)
			{
				_gl.uniform3fv(_programPointLightPositionUniform[i], params.pointLights[i].position, 0);

				// FIXME need array mapping of each ui pointlight element - how? * /
				_gl.uniform3f(_programPointLightAmbientUniform[i], params.ui.pointLight(i).pointLightAmbientColor.r,
					params.ui.pointLight(i).pointLightAmbientColor.g, params.ui.pointLight(i).pointLightAmbientColor.b);
				_gl.uniform3f(_programPointLightDiffuseUniform[i], params.ui.pointLight(i).pointLightDiffuseColor.r,
					params.ui.pointLight(i).pointLightDiffuseColor.g, params.ui.pointLight(i).pointLightDiffuseColor.b);
				_gl.uniform3f(_programPointLightSpecularUniform[i], params.ui.pointLight(i).pointLightSpecularColor.r,
					params.ui.pointLight(i).pointLightSpecularColor.g, params.ui.pointLight(i).pointLightSpecularColor.b);
				_gl.uniform1f(_programPointLightAttenuationKc[i], params.ui.pointLight(i).pointLightKc);
				_gl.uniform1f(_programPointLightAttenuationKl[i], params.ui.pointLight(i).pointLightKl);
				_gl.uniform1f(_programPointLightAttenuationKq[i], params.ui.pointLight(i).pointLightKq);
			}
		}

		// Flashlight
		_gl.uniform1i(_programFlashlightEnabledUniform, params.ui.flashlight ? 1 : 0);
		if (params.ui.flashlight)
		{
			_gl.uniform3fv(_programFlashlightPositionUniform, params.flashlightPos, 0);
			_gl.uniform3fv(_programFlashlightDirectionUniform, params.flashlightDir, 0);
			_gl.uniform3f(_programFlashlightAmbientUniform, params.ui.flashlightAmbientColor.r, params.ui.flashlightAmbientColor.g,
				params.ui.flashlightAmbientColor.b);
			_gl.uniform3f(_programFlashlightDiffuseUniform, params.ui.flashlightDiffuseColor.r, params.ui.flashlightDiffuseColor.g,
				params.ui.flashlightDiffuseColor.b);
			_gl.uniform3f(_programFlashlightSpecularUniform, params.ui.flashlightSpecularColor.r, params.ui.flashlightSpecularColor.g,
				params.ui.flashlightSpecularColor.b);
			_gl.uniform1f(_programFlashlightAttenuationKc, params.ui.flashlightKc);
			_gl.uniform1f(_programFlashlightAttenuationKl, params.ui.flashlightKl);
			_gl.uniform1f(_programFlashlightAttenuationKq, params.ui.flashlightKq);
			_gl.uniform1f(_programFlashlightInnerCutoffUniform, Math.cos(radians(params.ui.flashlightInnerCutoff)));
			_gl.uniform1f(_programFlashlightOuterCutoffUniform, Math.cos(radians(params.ui.flashlightOuterCutoff)));
		}

		// Lighting maps
		_gl.uniform1i(_programDiffuseLightMapUniform, 0); // Diffuse lighting map
		_context.setTextureAt(0, params.textures[0]);
		_gl.uniform1i(_programSpecularLightMapUniform, 1); // Specular lighting map
		_context.setTextureAt(1, params.textures[1]);
		_gl.uniform3fv(_programViewerPositionUniform, params.cameraPosition, 0);
		_gl.uniform1f(_programSpecularShininessUniform, Math.pow(2, params.ui.specularShininess));

		// Apply GL calls to submit the cube data to the GPU
		_context.setVertexBufferAt(_programVertexAttribute, params.vbo, 0, FLOAT_3);
		_context.setVertexBufferAt(_programTextureAttribute, params.vbo, 3, FLOAT_2);
		_context.setVertexBufferAt(_programColorAttribute, params.vbo, 5, FLOAT_4);
		_context.setVertexBufferAt(_programNormalAttribute, params.vbo, 9, FLOAT_3);

		_context.drawTriangles(params.ibo);
	}
}
