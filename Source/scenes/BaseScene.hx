package scenes;

import Camera.CameraLookTo;
import Camera.CameraMovement;
import MatrixUtils.createPerspectiveProjection;
import haxe.ValueException;
import lime.graphics.WebGLRenderContext;
import lime.math.RGBA;
import openfl.display.Sprite;
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

enum ControlTarget
{
	CAMERA;
	MODEL;
}

/**
 * The base scene class which is to be extended by all scenes.
 */
abstract class BaseScene extends Sprite
{
	var _ui:UI;

	// Graphics Contexts
	var _gl:WebGLRenderContext;

	// Control target - which object is controlled by the inputs
	var _controlTarget:ControlTarget;
	var _controlsEnabled:Bool;

	var _initialSceneRendered:Bool = false;

	// Camera
	var _camera:Camera;
	private var projectionTransform:Matrix3D;

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
	private var _deltaTime:Float;

	// Vectors and Matrices
	var _sceneRotation:Matrix3D;
	var _yaw:Float;
	var _pitch:Float;

	final ROTATION_SENSITIVTY = 0.5;

	/**
	 * Constructor
	 * @param ui the UI instance
	 */
	public function new(ui:UI)
	{
		super();

		_ui = ui;
		_controlsEnabled = !_ui.isVisible;
		_sceneRotation = new Matrix3D();

		// Setup input
		_controlTarget = MODEL;
		_gameInput = new GameInput();
		_gamepads = new Array<GameInputDevice>();

		addEventListener(Event.ADDED_TO_STAGE, sceneAddedToStage);
	}

	/**
	 * Update any scene state for this frame. Subclasses should override this if they need to do updates.
	 * @param elapsed time since the last update
	 */
	public function update(elapsed:Float):Void {};

	public function updateScene(elapsed:Float):Void
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
		update(elapsed);
	}

	/**
	 * Set up any initial state that cannot be setup in the constructor, such as event handlers,
	 * initial state and so on. Subclasses must not register this callback to the stage. The base class
	 * will call this method automatically on the scene being added to the stage.
	 * 
	 * @param e the stage event
	 */
	abstract function addedToStage(e:Event):Void;

	public function sceneAddedToStage(e:Event):Void
	{
		_gl = stage.window.context.webgl;

		// Register initial scene render completed handler
		// addEventListener(SceneEvent.SCENE_INITIAL_RENDER_END, _ui.clearSceneLoadingMessage);

		// Setup mouse
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseOnMove);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseOnWheel);

		// Add gamepad support
		_gameInput.addEventListener(GameInputEvent.DEVICE_ADDED, gameInputOnDeviceAdded);
		_gameInput.addEventListener(GameInputEvent.DEVICE_REMOVED, gameInputOnDeviceRemoved);

		// Setup keyboard handler
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		// Notify current scene
		addedToStage(e);

		removeEventListener(Event.ADDED_TO_STAGE, sceneAddedToStage);
	}

	/**
	 * Close the scene unregistering any event listeners and deallocating resources which cannot be cleaned up just by freeing the scene object.
	 */
	abstract function close():Void;

	public function closeScene():Void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseOnMove);
		stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseOnWheel);
		_gameInput.removeEventListener(GameInputEvent.DEVICE_ADDED, gameInputOnDeviceAdded);
		_gameInput.removeEventListener(GameInputEvent.DEVICE_REMOVED, gameInputOnDeviceRemoved);
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		close();
	}

	/**
	 * Render the current frame.
	 */
	abstract function render():Void;

	public function renderScene():Void
	{
		// Clear the screen and prepare for this frame
		var clearTo = getClearColor();
		_gl.clearColor(clearTo.r / 255.0, clearTo.g / 255.0, clearTo.b / 255.0, clearTo.a / 255.0);

		// Disable the stencil buffer because otherwise the floor will write to it and break the outlining.
		// This appears to be a side-affect of the OpenFL 2D render because it is only a problem when the UI is
		// visible.
		// FIXME need to setup these states based on the scene.
		_gl.disable(_gl.STENCIL_TEST);
		_gl.clear(_gl.COLOR_BUFFER_BIT | _gl.DEPTH_BUFFER_BIT | _gl.STENCIL_BUFFER_BIT);
		_gl.depthFunc(_gl.LESS);
		_gl.enable(_gl.DEPTH_TEST);

		// Render current scene
		render();

		// Send end of first render event
		// if (!_initialSceneRendered)
		// {
		// 	var evt = new SceneEvent(SceneEvent.SCENE_INITIAL_RENDER_END);
		// 	dispatchEvent(evt);

		// 	_initialSceneRendered = true;
		// }

		// Set depthFunc to always pass so that the 2D stage rendering follows render order
		// If you don't do this the UI will render badly, missing bits like text which is
		// probably behind the buttons it's on and such like.
		_gl.depthFunc(_gl.ALWAYS);
	}

	/**
	 * Get the color to clear to. Subclasses may override this function.
	 * @return RGBA
	 */
	function getClearColor():RGBA
	{
		return RGBA.create(0, 0, 0, 255);
	}

	/**
	 * Set controls to enabled or disabled. Enabled means that one can use the keyboard and mouse
	 * to control the camera or model in the scene. Disabled means that they operate on the UI.
	 * 
	 * @param enabled, true to enable, false to disable the controls.
	 */
	public function setControlsEnabled(enabled:Bool):Void
	{
		_controlsEnabled = enabled;
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
				rotateModel(e.localX - _mouseX, _mouseY - e.localY);
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

	/**
	 * Rotate the model in space.
	 * @param xOffset x axis offset from current value
	 * @param yOffset y axis offset from current value
	 */
	function rotateModel(xOffset:Float, yOffset:Float):Void
	{
		var deltaX = xOffset * ROTATION_SENSITIVTY;
		var deltaY = yOffset * ROTATION_SENSITIVTY;

		_yaw += deltaX;
		_pitch += deltaY;

		if (_pitch > 89)
		{
			_pitch = 89;
		}
		if (_pitch < -89)
		{
			_pitch = -89;
		}

		var rotation = new Matrix3D();
		rotation.appendRotation(_yaw, new Vector3D(0, 1, 0));
		rotation.appendRotation(_pitch, new Vector3D(1, 0, 0));
		_sceneRotation = rotation;
	}
}
