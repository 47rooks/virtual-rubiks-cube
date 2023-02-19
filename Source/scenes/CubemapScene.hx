package scenes;

import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createTranslationMatrix;
import MatrixUtils.removeTranslation;
import MatrixUtils.vector3DToFloat32Array;
import gl.ModelLoadingProgram;
import gl.SkyboxProgram;
import lights.Flashlight;
import lights.PointLight;
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
		// _camera.move_speed = 10;

		// Compute projection matrix
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 0.1, 1000.0);

		// // There are four point lights with positions scaled by 64.0 (which is the scale of the cube size)
		// // compared to DeVries original. Strictly this should be programmatically scaled by RubiksCube.SIDE.
		// // Previously used single point light location was [200.0, 200.0, 200.0]
		// _pointLights = new Array<PointLight>();
		// final pointLightPositions = [
		// 	[80.0, 100.0, 128.0],
		// 	[147.2, -211.2, -256.0],
		// 	[-256.0, 128.0, -768.0],
		// 	[0.0, 0.0, -192.0]
		// ];
		// for (i in 0...NUM_POINT_LIGHTS)
		// {
		// 	_pointLights[i] = new PointLight(new Float32Array(pointLightPositions[i]), LIGHT_COLOR, _gl);
		// }

		_cube = new CubeModel(_gl);
		_modelLoadingProgram = new ModelLoadingProgram(_gl);

		// Define skybox variables
		_skybox = new SkyboxModel(_gl);
		_skyboxProgram = new SkyboxProgram(_gl);
	}

	function close() {}

	function render()
	{
		var cameraPos = vector3DToFloat32Array(_camera.cameraPos);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);

		var translation = createTranslationMatrix(0.0, 0.0, 0.0);
		translation.append(_sceneRotation);

		_modelLoadingProgram.use();
		_cube.draw(_modelLoadingProgram, {
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

		_gl.depthFunc(_gl.LESS);

		// _modelLoading.render(_gl, lookAtMat, _lightPosition, _pointLights, cameraPos, vector3DToFloat32Array(_camera.cameraFront), _ui);

		// // Rendering the point light objects
		// // FIXME might reposition the lights - well point light 1 - it's in the way
		// for (i in 0...NUM_POINT_LIGHTS)
		// {
		// 	if (_ui.pointLight(i).uiPointLightEnabled.selected)
		// 	{
		// 		_pointLights[i].render(_gl, lookAtMat, _ui);
		// 	}
		// }
	}
}
