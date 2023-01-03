package scenes;

import Camera.CameraMovement;
import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.vector3DToFloat32Array;
import lights.Flashlight;
import lights.PointLight;
import lime.utils.Float32Array;
import models.Light;
import models.ModelLoading;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.ui.Keyboard;
import openfl.ui.Mouse;
import ui.UI;

/**
 * This class demonstrates the functionality of Part III in Learn OpenGL. Here we use GLTF2 rather than
 * OBJ/MTL but otherwise the principles are the same.
 */
class ModelLoadingScene extends BaseScene
{
	private var projectionTransform:Matrix3D;

	// Model Loading scene
	var _modelLoading:ModelLoading;

	// Mouse coordinates
	var _mouseX:Float;
	var _mouseY:Float;
	var _firstMove = true;
	private var _deltaTime:Float;

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

	// Camera
	var _camera:Camera;

	/**
	 * Constructor
	 * @param ui the UI instance
	 */
	public function new(ui:UI)
	{
		super(ui);

		_controlTarget = MODEL;
		_controlsEnabled = false;
		_deltaTime = 0;

		// FIXME is this needed
		_lightPosition = new Float32Array([200.0, 200.0, 200.0]);
	}

	/**
	 * Handle mouse movement events.
	 * FIXME - duplicates Scene.hx
	 * @param e 
	 */
	function mouseOnMove(e:MouseEvent):Void
	{
		if (!_controlsEnabled)
		{
			return;
		}

		if (_firstMove)
		{
			_mouseX = e.localX;
			_mouseY = e.localY;
			_firstMove = false;
		}

		switch (_controlTarget)
		{
			case CAMERA:
				_camera.lookAround(e.localX - _mouseX, _mouseY - e.localY);
			case MODEL:
				_modelLoading.rotate(e.localX - _mouseX, _mouseY - e.localY);
		}
		_mouseX = e.localX;
		_mouseY = e.localY;
	}

	function update(elapsed:Float)
	{
		_deltaTime = elapsed / 1000.0;

		if (_ui.mouseTargetsCube)
		{
			_controlTarget = MODEL;
		}
		else
		{
			_controlTarget = CAMERA;
		}

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

		_modelLoading = new ModelLoading(_gl, _context);

		// There are four point lights with positions scaled by 64.0 (which is the scale of the cube size)
		// compared to DeVries original. Strictly this should be programmatically scaled by RubiksCube.SIDE.
		// Previously used single point light location was [200.0, 200.0, 200.0]
		_pointLights = new Array<PointLight>();
		final pointLightPositions = [
			[44.8, 12.8, 128.0],
			[147.2, -211.2, -256.0],
			[-256.0, 128.0, -768.0],
			[0.0, 0.0, -192.0]
		];
		for (i in 0...NUM_POINT_LIGHTS)
		{
			_pointLights[i] = new PointLight(new Float32Array(pointLightPositions[i]), LIGHT_COLOR, _gl, _context);
		}

		// Setup mouse
		Mouse.hide();
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseOnMove);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
	}

	function close()
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseOnMove);
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
	}

	function render()
	{
		var cameraPos = vector3DToFloat32Array(_camera.cameraPos);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);

		_modelLoading.render(_gl, _context, lookAtMat, LIGHT_COLOR, _lightPosition, _pointLights, cameraPos, vector3DToFloat32Array(_camera.cameraFront), _ui);

		// Rendering the point light objects
		// FIXME might reposition the lights - well point light 1 - it's in the way
		for (i in 0...NUM_POINT_LIGHTS)
		{
			if (_ui.pointLight(i).uiPointLightEnabled.selected)
			{
				_pointLights[i].render(_gl, _context, lookAtMat, _ui);
			}
		}
	}

	/**
	 * Handle key press events
	 * 
	 * @param event keyboard event
	 */
	function keyHandler(event:KeyboardEvent):Void
	{
		if (!_controlsEnabled)
		{
			return;
		}

		switch (event.keyCode)
		{
			case Keyboard.M:
				if (_controlTarget == CAMERA)
				{
					_controlTarget = MODEL;
					_ui.mouseTargetsCube = true;
				}
				else if (_controlTarget == MODEL)
				{
					_controlTarget = CAMERA;
					_ui.mouseTargetsCube = false;
				}
			case Keyboard.W:
				_camera.move(CameraMovement.FORWARD, _deltaTime);
			case Keyboard.S:
				_camera.move(CameraMovement.BACKWARD, _deltaTime);
			case Keyboard.A:
				_camera.move(CameraMovement.LEFT, _deltaTime);
			case Keyboard.D:
				_camera.move(CameraMovement.RIGHT, _deltaTime);
			default:
		}
	}
}
