package scenes;

import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.vector3DToFloat32Array;
import lights.Flashlight;
import lights.PointLight;
import lime.utils.Float32Array;
import models.Light;
import models.ModelLoading;
import openfl.events.Event;
import openfl.geom.Vector3D;
import ui.UI;

/**
 * This class demonstrates the functionality of Part III in Learn OpenGL. Here we use GLTF2 rather than
 * OBJ/MTL but otherwise the principles are the same.
 */
class ModelLoadingScene extends BaseScene
{
	// Model Loading scene
	var _modelLoading:ModelLoading;

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

	override function rotateModel(xOffset:Float, yOffset:Float):Void
	{
		_modelLoading.rotate(xOffset, yOffset);
	}

	override function update(elapsed:Float)
	{
		_modelLoading.update(elapsed, _ui);
	}

	function addedToStage(e:Event)
	{
		_camera = new Camera(new Vector3D(0, 0, 500), new Vector3D(0, 1, 0));

		// Compute projection matrix
		// Uncomment the createOrthoProjection() line and comment the next for an orthographic view.
		// Note that mouse wheel zoom will switch back to perspective projection as it
		//      recreates the projection matrix and only supports doing so for the
		//      perspective projection. See mouseOnWheel().
		// projectionTransform = createOrthoProjection(-300.0, 300.0, 300.0, -300.0, 100, 1000);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		_modelLoading = new ModelLoading(_gl);

		// There are four point lights with positions scaled by 64.0 (which is the scale of the cube size)
		// compared to DeVries original. Strictly this should be programmatically scaled by RubiksCube.SIDE.
		// Previously used single point light location was [200.0, 200.0, 200.0]
		_pointLights = new Array<PointLight>();
		final pointLightPositions = [
			[80.0, 100.0, 128.0],
			[147.2, -211.2, -256.0],
			[-256.0, 128.0, -768.0],
			[0.0, 0.0, -192.0]
		];
		for (i in 0...NUM_POINT_LIGHTS)
		{
			_pointLights[i] = new PointLight(new Float32Array(pointLightPositions[i]), LIGHT_COLOR, _gl);
		}
	}

	function close() {}

	function render()
	{
		var cameraPos = vector3DToFloat32Array(_camera.cameraPos);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);

		_modelLoading.render(_gl, lookAtMat, _lightPosition, _pointLights, cameraPos, vector3DToFloat32Array(_camera.cameraFront), _ui);

		// Rendering the point light objects
		// FIXME might reposition the lights - well point light 1 - it's in the way
		for (i in 0...NUM_POINT_LIGHTS)
		{
			if (_ui.pointLight(i).uiPointLightEnabled.selected)
			{
				_pointLights[i].render(_gl, lookAtMat, _ui);
			}
		}
	}
}
