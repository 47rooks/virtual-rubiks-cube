package scenes;

import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createTranslationMatrix;
import MatrixUtils.removeTranslation;
import MatrixUtils.vector3DToFloat32Array;
import gl.EnvironmentmapProgram;
import gl.ModelLoadingProgram;
import gl.SkyboxProgram;
import lights.Flashlight;
import lights.PointLight;
import lime.graphics.opengl.GLTexture;
import lime.utils.Assets;
import lime.utils.Float32Array;
import models.Light;
import models.ModelLoading;
import models.logl.CubeModel;
import models.logl.SkyboxModel;
import openfl.events.Event;
import openfl.geom.Vector3D;
import ui.UI;

/**
 * A scene to support the Skybox (Cubemap) and environment mapping demos.
 */
class CubemapScene extends BaseScene
{
	// Model Loading scene
	var _modelLoading:ModelLoading;
	var _modelLoadingProgram:ModelLoadingProgram;
	var _EnvironmentmapProgram:EnvironmentmapProgram;
	var _cube:CubeModel;

	// Lights
	// Simple 3-component light
	var _light:Light;
	final LIGHT_COLOR = WHITE;
	final _lightPosition:Float32Array;

	// Point Light
	var _pointLights:Array<PointLight>;

	public static final NUM_POINT_LIGHTS = 4;

	// Flashlight
	var _flashlight:Flashlight;

	// Skybox texture id
	var _skyboxTexture:GLTexture;
	var _skybox:SkyboxModel;
	var _skyboxProgram:SkyboxProgram;

	/**
	 * Constructor
	 * @param ui the UI instance
	 */
	public function new(ui:UI)
	{
		super(ui);

		_deltaTime = 0;

		// FIXME is this needed
		_lightPosition = new Float32Array([200.0, 200.0, 200.0]);
	}

	function addedToStage(e:Event)
	{
		_camera = new Camera(new Vector3D(0, 0, 100.0), new Vector3D(0, 1, 0));

		// Compute projection matrix
		projectionTransform = createPerspectiveProjection(_camera.fov, 640.0 / 480.0, 0.1, 1000.0);

		_skyboxTexture = loadSkyboxTexture();

		_cube = new CubeModel(_gl);
		_modelLoadingProgram = new ModelLoadingProgram(_gl);
		_EnvironmentmapProgram = new EnvironmentmapProgram(_gl);

		// Define skybox variables
		_skybox = new SkyboxModel(_gl, _skyboxTexture);
		_skyboxProgram = new SkyboxProgram(_gl);
	}

	function close() {}

	/**
	 * Render the scene.
	 * 
	 * Note that in this scene the cubemap texture is loaded here in the scene and bound to the expected
	 * texture and target before each shader is called. This is a bit of a hack to work with the
	 * current program structures because they mostly expect to bind textures in the programs. But in
	 * a real system textures which are not loaded specifically with models would probably be loaded
	 * in this or a similar way so they could be shared.
	 */
	function render()
	{
		var cameraPos = vector3DToFloat32Array(_camera.cameraPos);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);

		var translation = createTranslationMatrix(0.0, 0.0, 0.0);
		translation.append(_sceneRotation);

		_gl.activeTexture(_gl.TEXTURE1); // Bind skybox texture to TEXTURE2.
		_gl.bindTexture(_gl.TEXTURE_CUBE_MAP, _skyboxTexture);
		_gl.activeTexture(0);
		_EnvironmentmapProgram.use();
		_cube.draw(_EnvironmentmapProgram, {
			vbo: null,
			vertexBufferData: null,
			ebo: null,
			numIndexes: 0,
			indexBufferData: null,
			textures: null,
			modelMatrix: translation,
			projectionMatrix: lookAtMat,
			cameraPosition: cameraPos,
			lightColor: null,
			lightPosition: null,
			directionalLight: lightDirection,
			pointLights: _pointLights,
			flashlightPos: cameraPos,
			flashlightDir: vector3DToFloat32Array(_camera.cameraFront),
			ui: _ui
		});

		_gl.depthFunc(_gl.LEQUAL);

		_skyboxProgram.use();
		_gl.activeTexture(_gl.TEXTURE0); // Assign skybox to texture 0
		_gl.bindTexture(_gl.TEXTURE_CUBE_MAP, _skyboxTexture);
		var viewNoTx = removeTranslation(_camera.getViewMatrix());
		_skybox.draw(_skyboxProgram, {
			vbo: null,
			vertexBufferData: null,
			ebo: null,
			numIndexes: 0,
			indexBufferData: null,
			textures: null,
			modelMatrix: viewNoTx,
			projectionMatrix: projectionTransform,
			cameraPosition: null,
			lightColor: null,
			lightPosition: null,
			directionalLight: null,
			pointLights: null,
			flashlightPos: null,
			flashlightDir: null,
			ui: _ui
		});
		_gl.activeTexture(_gl.TEXTURE0);

		_gl.depthFunc(_gl.LESS);

		// _modelLoading.render(_gl, lookAtMat, _lightPosition, _pointLights, cameraPos, vector3DToFloat32Array(_camera.cameraFront), _ui);
	}

	/**
	 * Load the skyboax texture. The reason the skybox is loaded here is that it is used in
	 * both by the skybox and by the model for environment mapping. This allows the one texture
	 * to be shared with multiple models. Of course in a production program many textures would
	 * likely be loaded into a library of models and shared.
	 * 
	 * @return GLTexture
	 */
	private function loadSkyboxTexture():GLTexture
	{
		var faces = [
			"assets/skybox/right.jpg",
			"assets/skybox/left.jpg",
			"assets/skybox/top.jpg",
			"assets/skybox/bottom.jpg",
			"assets/skybox/back.jpg",
			"assets/skybox/front.jpg"
		];

		_gl.activeTexture(_gl.TEXTURE2);
		var tex = _gl.createTexture();
		_gl.bindTexture(_gl.TEXTURE_CUBE_MAP, tex);
		for (i => path in faces)
		{
			var img = Assets.getImage(path);
			_gl.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, _gl.RGBA, img.buffer.width, img.buffer.height, 0, _gl.RGBA, _gl.UNSIGNED_BYTE,
				img.buffer.data);
		}
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_MIN_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_MAG_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_WRAP_S, _gl.CLAMP_TO_EDGE);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_WRAP_T, _gl.CLAMP_TO_EDGE);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_WRAP_R, _gl.CLAMP_TO_EDGE);
		_gl.activeTexture(0);
		_gl.bindTexture(_gl.TEXTURE_CUBE_MAP, null);
		return tex;
	}
}
