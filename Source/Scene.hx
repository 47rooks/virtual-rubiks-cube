package;

import Camera.CameraLookTo;
import Camera.CameraMovement;
import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.vector3DToFloat32Array;
import haxe.ValueException;
import lights.Flashlight;
import lights.PointLight;
import lime.utils.Float32Array;
import models.CubeCloud;
import models.Light;
import models.RubiksCube;
import openfl.events.Event;
import openfl.events.GameInputEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.ui.GameInput;
import openfl.ui.GameInputControl;
import openfl.ui.GameInputDevice;
import openfl.ui.Keyboard;
import openfl.ui.Mouse;
import scenes.BaseScene;
import ui.UI;

enum abstract GamepadControl(Int)
{
	final A = 6;
	final B = 7;
	final X = 8;
	final Y = 9;
	final VIEW = 10;
	final UNUSED1 = 11;
	final MENU = 12;
	final LEFT_STICK_BUTTON = 13;
	final RIGHT_STICK_BUTTON = 14;
	final LEFT_BUMPER = 15;
	final RIGHT_BUMPER = 16;
	final DPAD_UP = 17;
	final DPAD_DOWN = 18;
	final DPAD_LEFT = 19;
	final DPAD_RIGHT = 20;
	final LEFT_STICK_HORIZONTAL = 0;
	final LEFT_STICK_VERTICAL = 1;
	final RIGHT_STICK_HORIZONTAL = 2;
	final RIGHT_STICK_VERTICAL = 3;
	final LEFT_TRIGGER = 4;
	final RIGHT_TRIGGER = 5;
	static final mappings = [
		0 => {id: 'AXIS_0', index: 0},
		1 => {id: 'AXIS_1', index: 1},
		2 => {id: 'AXIS_2', index: 2},
		3 => {id: 'AXIS_3', index: 3},
		4 => {id: 'AXIS_4', index: 4},
		5 => {id: 'AXIS_5', index: 5},
		6 => {id: 'BUTTON_0', index: 6},
		7 => {id: 'BUTTON_1', index: 7},
		8 => {id: 'BUTTON_2', index: 8},
		9 => {id: 'BUTTON_3', index: 9},
		10 => {id: 'BUTTON_4', index: 10},
		11 => {id: 'BUTTON_5', index: 11},
		12 => {id: 'BUTTON_6', index: 12},
		13 => {id: 'BUTTON_7', index: 13},
		14 => {id: 'BUTTON_8', index: 14},
		15 => {id: 'BUTTON_9', index: 15},
		16 => {id: 'BUTTON_10', index: 16},
		17 => {id: 'BUTTON_11', index: 17},
		18 => {id: 'BUTTON_12', index: 18},
		19 => {id: 'BUTTON_13', index: 19},
		20 => {id: 'BUTTON_14', index: 20}
	];

	/**
	 * Get the index value for this control.
	 */
	@:to
	public function toIndex():Int
	{
		return mappings[this].index;
	}

	@:from
	public static function fromStr(s:String):GamepadControl
	{
		for (i => m in mappings)
		{
			if (m.id == s)
				return cast i;
		}
		throw new ValueException('no control exists for id ${s}');
	}
}

enum SceneSubType
{
	RUBIKS;
	RUBIKS_WITH_LIGHT;
	CUBE_CLOUD;
}

/**
 * Scene is the world for this Rubik's cube program. It contains all the world objects and drives
 * the rendering of all of them. It is created in the normal way of doing most of the work in
 * the ADDED_TO_STAGE event handler.
 * 
 * It does contain some experimental gamepad support but it is by no means complete or fully worked
 * out.
 */
class Scene extends BaseScene
{
	private var projectionTransform:Matrix3D;
	private var _deltaTime:Float;

	// Objects
	/* Rubik's cube */
	var _rubiksCube:RubiksCube;
	var operations:Array<Operation>;
	var operNum:Int;

	// Cube Cloud
	var _cubeCloud:CubeCloud;

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

	// Gamepad input
	var _gameInput:GameInput;
	var _gamepads:Array<GameInputDevice>;
	var _gamepadRightStickX:Float;
	var _gamepadRightStickY:Float;
	var _gamepadFirstMoveRightStickX = true;
	var _gamepadFirstMoveRightStickY = true;

	var _gamepadLookAtX:Float;
	var _gamepadLookAtY:Float;
	var _gamepadLookAtFirstMove:Bool = true;

	// Mouse coordinates
	var _mouseX:Float;
	var _mouseY:Float;
	var _firstMove = true;

	public function new(ui:UI)
	{
		super(ui);

		// Initialize key fields
		_deltaTime = 0;

		_camera = new Camera(new Vector3D(0, 0, 500), new Vector3D(0, 1, 0));

		// Setup input
		_controlTarget = MODEL;
		_gameInput = new GameInput();
		_gamepads = new Array<GameInputDevice>();

		_lightPosition = new Float32Array([200.0, 200.0, 200.0]);
	}

	function addedToStage(e:Event):Void
	{
		_gl = stage.window.context.webgl;
		_context = stage.context3D;

		// Compute projection matrix
		// Uncomment the createOrthoProjection() line and comment the next for an orthographic view.
		// Note that mouse wheel zoom will switch back to perspective projection as it
		//      recreates the projection matrix and only supports doing so for the
		//      perspective projection. See mouseOnWheel().
		// projectionTransform = createOrthoProjection(-300.0, 300.0, 300.0, -300.0, 100, 1000);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		// GL  comment for now
		_rubiksCube = new RubiksCube(Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this, _gl, _context);

		// Add lights
		_light = new Light(_lightPosition, LIGHT_COLOR, _gl, _context);

		_cubeCloud = new CubeCloud(_gl, _context);

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

		_flashlight = new Flashlight(vector3DToFloat32Array(_camera.cameraPos), vector3DToFloat32Array(_camera.cameraFront), 30, _gl, _context);

		// Add completion event listener
		addEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, nextOperation);

		// Add key listener to start example rotations
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		// Setup the operations
		operations = new Array<Operation>();
		operNum = 0;

		// Setup mouse
		Mouse.hide();
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseOnMove);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseOnWheel);

		// Add gamepad support
		_gameInput.addEventListener(GameInputEvent.DEVICE_ADDED, gameInputOnDeviceAdded);
		_gameInput.addEventListener(GameInputEvent.DEVICE_REMOVED, gameInputOnDeviceRemoved);
	}

	function close():Void
	{
		removeEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, nextOperation);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseOnMove);
		stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseOnWheel);
		_gameInput.removeEventListener(GameInputEvent.DEVICE_ADDED, gameInputOnDeviceAdded);
		_gameInput.removeEventListener(GameInputEvent.DEVICE_REMOVED, gameInputOnDeviceRemoved);
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
	}

	/**
	 * Set the scene objects according to the selected mode.
	 * For the moment this is a simple hack to return an enum.
	 * Ultimately we need an interface def (update/render) for
	 * all scene objects.
	 * @param ui UI parameters
	 */
	private function setScene(ui:UI):SceneSubType
	{
		if (ui.sceneCubeCloud)
		{
			return SceneSubType.CUBE_CLOUD;
		}
		else if (ui.sceneRubiksWithLight)
		{
			return SceneSubType.RUBIKS_WITH_LIGHT;
		}

		return SceneSubType.RUBIKS;
	}

	/**
	 * Update the current state.
	 * 
	 * @param elapsed elapsed time since last call.
	 */
	function update(elapsed:Float):Void
	{
		_deltaTime = elapsed / 1000.0;

		// Poll inputs that require it
		for (gp in _gamepads)
		{
			pollGamepad(gp);
		}

		if (_ui.mouseTargetsCube)
		{
			_controlTarget = MODEL;
		}
		else
		{
			_controlTarget = CAMERA;
		}

		// FIXME Add a configure scene method that sets up the right collection of object
		// based on the selected scene.
		switch (setScene(_ui))
		{
			case RUBIKS:
				{
					_rubiksCube.update(elapsed);
				}
			case RUBIKS_WITH_LIGHT:
				{
					_rubiksCube.update(elapsed);
				}
			case CUBE_CLOUD:
				{
					_cubeCloud.update(elapsed);
				}
		}
		// FIXME remove ?_rubiksCube.update(elapsed);
	}

	function render():Void
	{
		// Clear the screen and prepare for this frame
		if (_ui.sceneRubiks)
		{
			_gl.clearColor(0.53, 0.81, 0.92, 1); // Clear to sky blue
		}
		else
		{
			_gl.clearColor(0, 0, 0, 1); // Clear to black
		}
		_gl.clear(_gl.COLOR_BUFFER_BIT | _gl.DEPTH_BUFFER_BIT);
		_gl.depthFunc(_gl.LESS);
		_gl.depthMask(true);
		_gl.enable(_gl.DEPTH_TEST);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);

		switch (setScene(_ui))
		{
			case RUBIKS:
				{
					_rubiksCube.render(_gl, _context, lookAtMat, LIGHT_COLOR, _lightPosition, vector3DToFloat32Array(_camera.cameraPos), _ui);
				}
			case RUBIKS_WITH_LIGHT:
				{
					_rubiksCube.render(_gl, _context, lookAtMat, LIGHT_COLOR, _lightPosition, vector3DToFloat32Array(_camera.cameraPos), _ui);
					_light.render(_gl, _context, lookAtMat, _ui);
				}
			case CUBE_CLOUD:
				{
					var cameraPos = vector3DToFloat32Array(_camera.cameraPos);
					_cubeCloud.render(_gl, _context, lookAtMat, LIGHT_COLOR, _lightPosition, cameraPos, _pointLights, cameraPos,
						vector3DToFloat32Array(_camera.cameraFront), _ui);
					for (i in 0...NUM_POINT_LIGHTS)
					{
						if (_ui.pointLight(i).uiPointLightEnabled.selected)
						{
							_pointLights[i].render(_gl, _context, lookAtMat, _ui);
						}
					}
				}
		}

		// Set depthFunc to always pass so that the 2D stage rendering follows render order
		// If you don't do this the UI will render badly, missing bits like text which is
		// probably behind the buttons it's on and such like.
		_gl.depthFunc(_gl.ALWAYS);
	}

	/**
	 * Handler to progress to the next operation in the list.
	 * @param event the completion event.
	 */
	function nextOperation(event:OperationCompleteEvent):Void
	{
		trace('operation completed');
		if (operNum < operations.length - 1)
		{
			_rubiksCube.doOperation(operations[++operNum]);
		}
		else
		{
			trace('completed last operation');
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
			case Keyboard.R:
				// Perform rotation operation on a slice.
				operations = new Array<Operation>();
				operations.push(Operation.RotateSlice(Axis.X, 1, 90));
				operations.push(Operation.RotateSlice(Axis.Y, 1, 90));
				operations.push(Operation.RotateSlice(Axis.Z, 1, 90));
				_rubiksCube.doOperation(operations[0]);
				operNum = 0;
			// case Keyboard.P:
			// 	// Dump matrix transformation of cube vertices
			// 	var m = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
			// 	m.append(projectionTransform);
			// 	_rubiksCube.dumpTransformVertices(m);
			default:
		}
	}

	/**
	 * Handle mouse movement events.
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
				_rubiksCube.rotate(e.localX - _mouseX, _mouseY - e.localY);
		}
		_mouseX = e.localX;
		_mouseY = e.localY;
	}

	/**
	 * Handle mouse wheel movement
	 * @param e 
	 */
	function mouseOnWheel(e:MouseEvent):Void
	{
		if (!_controlsEnabled)
		{
			return;
		}

		_camera.zoom(e.delta);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);
	}

	/**
	 * Handle the addition of a new game input device (gamepad).
	 * 
	 * @param event the triggering event
	 */
	function gameInputOnDeviceAdded(event:GameInputEvent):Void
	{
		var device = event.device;
		// Add control handler listenerss
		for (cId in 0...device.numControls)
		{
			var ctl = device.getControlAt(cId);
			if (cId == 2 || cId == 3)
				continue;
			ctl.addEventListener(Event.CHANGE, gameInputOnChange);
		}

		device.enabled = true;
		_gamepads.push(device);
	}

	/**
	 * Handle the removal of a game input device (gamepad).
	 * 
	 * @param event 
	 */
	private function gameInputOnDeviceRemoved(event:GameInputEvent):Void
	{
		var device = event.device;
		device.enabled = false;
		_gamepads.remove(device);
	}

	/**
	 * Process gamepad input
	 * @param e event container the changes in the control
	 */
	function gameInputOnChange(e:Event):Void
	{
		trace('evt target=${e.target}');
		var gic = cast(e.target, GameInputControl);
		trace('ctl=${gic.id} value = ${gic.value}');
		switch (GamepadControl.fromStr(gic.id))
		{
			case LEFT_STICK_HORIZONTAL:
				trace('Left Stick Horizontal Axis hit ${gic.value}');
				if (gic.value > 0)
				{
					_camera.move(CameraMovement.RIGHT, _deltaTime);
				}
				else
				{
					_camera.move(CameraMovement.LEFT, _deltaTime);
				}
			case LEFT_STICK_VERTICAL:
				trace('Left Stick Vertical Axis hit ${gic.value}');
				if (gic.value > 0)
				{
					_camera.move(CameraMovement.BACKWARD, _deltaTime);
				}
				else
				{
					_camera.move(CameraMovement.FORWARD, _deltaTime);
				}
			case RIGHT_STICK_HORIZONTAL:
				{}
			// if (gic.value > 0)
			// {
			// 	_camera.lookAround(CameraLookTo.RIGHT, _deltaTime);
			// }
			// else
			// {
			// 	_camera.lookAround(CameraLookTo.LEFT, _deltaTime);
			// }
			// Make right behave like the mouse - screen coords
			// var val = gic.value * stage.window.width / (gic.maxValue - gic.minValue);
			// if (_gamepadFirstMoveRightStickX)
			// {
			// 	_gamepadRightStickX = val;
			// 	_gamepadFirstMoveRightStickX = false;
			// }

			// _camera.lookAround(val - _gamepadRightStickX, 0);
			// _gamepadRightStickX = val;
			case RIGHT_STICK_VERTICAL:
				if (gic.value > 0)
				{
					_camera.lookAround(CameraLookTo.UP, _deltaTime);
				}
				else
				{
					_camera.lookAround(CameraLookTo.DOWN, _deltaTime);
				}

			// Make right behave like the mouse - screen coords
			// var v = gic.value * stage.window.height / (gic.maxValue - gic.minValue);
			// 	if (_gamepadFirstMoveRightStickY)
			// 	{
			// 		_gamepadRightStickY = v;
			// 		_gamepadFirstMoveRightStickY = false;
			// 	}

			// 	_camera.lookAround(0, _gamepadRightStickY - v);
			// 	_gamepadRightStickY = v;
			// case 'AXIS_4':
			// 	trace('Left trigger hit');
			// case 'AXIS_5':
			// 	trace('Right trigger hit');
			default:
				trace('${gic.id} UNKNOWN hit');
		}
	}

	/**
	 * Prototype poll function for gamepad controls
	 * FIXME The mapping is problematic because unlike the mouse this control springs back to center
	 * which moves the camera to look back to its original front vector.
	 * @param gp 
	 */
	function pollGamepad(gp:GameInputDevice):Void
	{
		if (!_controlsEnabled)
		{
			return;
		}

		// Poll gamepad right stick for look around
		if (gp != null)
		{
			var gp = _gamepads[0];
			var horizCtl = gp.getControlAt(RIGHT_STICK_HORIZONTAL.toIndex());
			var xVal = horizCtl.value * stage.window.width / (horizCtl.maxValue - horizCtl.minValue);
			var vertCtl = gp.getControlAt(RIGHT_STICK_VERTICAL.toIndex());
			var yVal = vertCtl.value * stage.window.height / (vertCtl.maxValue - vertCtl.minValue);
			if (_gamepadLookAtFirstMove)
			{
				_gamepadLookAtX = xVal;
				_gamepadLookAtY = yVal;
				_gamepadLookAtFirstMove = false;
			}

			var deltaX = xVal - _gamepadLookAtX;
			var deltaY = _gamepadLookAtY - yVal;
			if (deltaX != 0 || deltaY != 0)
			{
				_camera.lookAround(deltaX, deltaY);
				_gamepadLookAtX = xVal;
				_gamepadLookAtY = yVal;
			}
		}
	}
}
