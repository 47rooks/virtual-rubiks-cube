package;

import Camera.CameraLookTo;
import Camera.CameraMovement;
import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import RubiksCube.Axis;
import RubiksCube.Operation;
import haxe.ValueException;
import lime.graphics.WebGLRenderContext;
import openfl.display.BitmapData;
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
import openfl.ui.Mouse;

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
	RUBIKS_CUBE;
}

class Scene extends Sprite
{
	private var projectionTransform:Matrix3D;
	private var _deltaTime:Float;
	var _rubiksCube:RubiksCube;
	var operations:Array<Operation>;
	var operNum:Int;
	var _bg:BitmapData;

	// Lights
	var _light:Light;
	final LIGHT_COLOR = WHITE;

	// Camera
	var _camera:Camera;

	// Control target - which object is controlled by the inputs
	var _controlTarget:ControlTarget;

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

	public function new()
	{
		super();

		// Initialize key fields
		_deltaTime = 0;

		_camera = new Camera(new Vector3D(0, 0, 500), new Vector3D(0, 1, 0));

		// Setup input
		_controlTarget = CAMERA;
		_gameInput = new GameInput();
		_gamepads = new Array<GameInputDevice>();

		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
	}

	function addedToStage(e:Event):Void
	{
		// _bg = Assets.getBitmapData('assets/openfl.png');

		// AGAL
		// var context = stage.context3D;
		// context.configureBackBuffer(stage.stageWidth, stage.stageHeight, 1, true);

		// computeOrthoProjection();
		// projectionTransform = createOrthoProjection(-300.0, 300.0, 300.0, -300.0, 100, 1000);
		// projectionTransform = createPerspectiveProjection(-320, 320, 240, -240, 300, 800.0);
		// projectionTransform = createPerspectiveProjection(_cameraFOV, 640 / 480, 100, 1000);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		// AGAL
		// _rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this);
		// GL  comment for now
		// _rubiksCube = new RubiksCube(Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this);
		// _rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), 0, this);
		// _rubiksCube = new RubiksCube(context, 300, Math.ceil(stage.stageHeight / 2), 400, this);
		// addChild(new Bitmap(_bg));

		// Add lights
		// FIXME temporarily disable
		_light = new Light(200, 200, 200, LIGHT_COLOR);

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

	/**
	 * Update the current state.
	 * 
	 * @param elapsed elapsed time since last call.
	 */
	public function update(elapsed:Float):Void
	{
		_deltaTime = elapsed / 1000.0;

		// Poll inputs that require it
		for (gp in _gamepads)
		{
			pollGamepad(gp);
		}

		// _rubiksCube.update(elapsed);
	}

	// AGAL
	// /**
	//  * Render the scene for this frame. Assumes that `update` has already been called.
	//  */
	// public function render(gl:WebGLRenderContext):Void
	// {
	// 	var context = stage.context3D;
	// 	context.clear();
	// 	context.setDepthTest(true, Context3DCompareMode.LESS);
	// 	context.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);
	// 	// Render scene - iterate all objects and render them
	// 	// var lookAtMat = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
	// 	var lookAtMat = _camera.getViewMatrix();
	// 	// var lookAtMat = createLookAtMatrix(_cameraPos, _target, _worldUp);
	// 	lookAtMat.append(projectionTransform);
	// 	// Render the scene objects
	// 	_rubiksCube.render(lookAtMat, LIGHT_COLOR);
	// 	_light.render(lookAtMat);
	// 	// ------ finish iteration
	// 	context.present();
	// }

	public function render(gl:WebGLRenderContext):Void
	{
		// glInitialize(gl);
		// if (glRubiksCubeProgram == null)
		// {
		// 	return;
		// }
		// Render scene - iterate all objects and render them
		// var lookAtMat = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);

		// Clear the screen for this cycle
		gl.clearColor(0, 0, 0, 1);
		gl.enable(gl.DEPTH_TEST);
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

		var lookAtMat = _camera.getViewMatrix();
		// var lookAtMat = createLookAtMatrix(_cameraPos, _target, _worldUp);
		lookAtMat.append(projectionTransform);
		_light.render(gl, lookAtMat);
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
		switch (event.keyCode)
		{
			case Keyboard.M:
				if (_controlTarget == CAMERA)
				{
					_controlTarget = RUBIKS_CUBE;
				}
				else
				{
					_controlTarget = CAMERA;
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
			case RUBIKS_CUBE:
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
			trace('cId=${cId}=${ctl.id}');
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
