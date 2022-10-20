package;

import MatrixUtils.radians;
import openfl.events.MouseEvent;
import openfl.ui.Mouse;
import lime.ui.GamepadButton;
import openfl.ui.GameInputControl;
import openfl.events.EventType;
import openfl.events.GameInputEvent;
import openfl.ui.GameInputDevice;
import openfl.ui.GameInput;
import openfl.Lib;
import MatrixUtils.createOrthoProjection;
import MatrixUtils.createLookAtMatrix;
import MatrixUtils.createPerspectiveProjection;
import openfl.display.Bitmap;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Vector3D;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import RubiksCube.Operation;
import openfl.events.Event;
import openfl.Vector;
import RubiksCube.Axis;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.Matrix3D;
import openfl.display.Sprite;

class Scene extends Sprite
{
	private var projectionTransform:Matrix3D;

	private var _cumTime:Float;

	var _rubiksCube:RubiksCube;

	var operations:Array<Operation>;
	var operNum:Int;

	var _bg:BitmapData;

	// Camera and world vectors
	var _cameraPos:Vector3D;
	var _target:Vector3D;
	var _cameraFront:Vector3D;
	var _worldUp:Vector3D;
	var _cameraSpeed = 5;
	var _cameraAngle = 0;
	var _cameraFOV = 45.0; // Field of View in degrees
	var _yaw:Float;
	var _pitch:Float;

	// Gamepad input
	var _gameInput:GameInput;
	var _gamepads:Array<GameInputDevice>;

	// Mouse coordinates
	var _mouseX:Float;
	var _mouseY:Float;
	final SENSITIVITY = 0.5;
	var _firstMove = true;

	public function new():Void
	{
		super();

		// Initialize key fields
		_cumTime = 0;

		// _cameraPos = new Vector3D(270, 270, 270);
		// _cameraPos = new Vector3D(0, 500, 500);
		_cameraPos = new Vector3D(0, 0, 500);
		_cameraFront = new Vector3D(0, 0, -1);
		_target = new Vector3D(0, 0, 0);
		_worldUp = new Vector3D(0, 1, 0);
		_yaw = -90.0;
		_pitch = 0;

		// Setup input
		_gameInput = new GameInput();
		_gamepads = new Array<GameInputDevice>();

		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
	}

	function addedToStage(e:Event):Void
	{
		// _bg = Assets.getBitmapData('assets/openfl.png');

		var context = stage.context3D;
		// computeOrthoProjection();
		// projectionTransform = createOrthoProjection(-300.0, 300.0, 300.0, -300.0, 100, 1000);
		// projectionTransform = createPerspectiveProjection(-320, 320, 240, -240, 300, 800.0);
		projectionTransform = createPerspectiveProjection(_cameraFOV, 640 / 480, 100, 1000);

		_rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this);
		// _rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), 0, this);
		// _rubiksCube = new RubiksCube(context, 300, Math.ceil(stage.stageHeight / 2), 400, this);
		// addChild(new Bitmap(_bg));

		// Add completion event listener
		addEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, next_operation);

		// Add key listener to start example rotations
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		// Setup the operations
		operations = new Array<Operation>();
		operNum = 0;

		// Setup mouse
		Mouse.hide();
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouse_onMove);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouse_onWheel);

		// Add gamepad support
		_gameInput.addEventListener(GameInputEvent.DEVICE_ADDED, gameInput_onDeviceAdded);
		_gameInput.addEventListener(GameInputEvent.DEVICE_REMOVED, gameInput_onDeviceRemoved);
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
			case Keyboard.W:
				var tgt = _cameraFront.clone();
				tgt.scaleBy(_cameraSpeed);
				_cameraPos = _cameraPos.add(tgt);
			case Keyboard.S:
				var tgt = _cameraFront.clone();
				tgt.scaleBy(_cameraSpeed);
				_cameraPos = _cameraPos.subtract(tgt);
			case Keyboard.A:
				var m = _cameraFront.crossProduct(_worldUp);
				m.normalize();
				m.scaleBy(_cameraSpeed);
				_cameraPos = _cameraPos.subtract(m);
			case Keyboard.D:
				var m = _cameraFront.crossProduct(_worldUp);
				m.normalize();
				m.scaleBy(_cameraSpeed);
				_cameraPos = _cameraPos.add(m);
			// case Keyboard.Z:
			// 	_cameraAngle++;
			// 	var l = _cameraPos.length;
			// 	_cameraPos.x = l * Math.sin(_cameraAngle / Math.PI * 0.1);
			// 	_cameraPos.z = l * Math.cos(_cameraAngle / Math.PI * 0.1);
			// case Keyboard.C:
			// 	_cameraAngle--;
			// 	var l = _cameraPos.length;
			// 	_cameraPos.x = l * Math.sin(_cameraAngle / Math.PI * 0.1);
			// 	_cameraPos.z = l * Math.cos(_cameraAngle / Math.PI * 0.1);
			case Keyboard.R:
				// Perform rotation operation on a slice.
				operations = new Array<Operation>();
				operations.push(Operation.RotateSlice(Axis.X, 1, 90));
				operations.push(Operation.RotateSlice(Axis.Y, 1, 90));
				operations.push(Operation.RotateSlice(Axis.Z, 1, 90));
				_rubiksCube.doOperation(operations[0]);
				operNum = 0;
			case Keyboard.P:
				// Dump matrix transformation of cube vertices
				var m = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
				m.append(projectionTransform);
				_rubiksCube.dumpTransformVertices(m);
			default:
		}
	}

	/**
	 * Update the current state.
	 * 
	 * @param elapsed elapsed time since last call.
	 */
	public function update(elapsed:Float):Void
	{
		_cumTime += elapsed;

		_rubiksCube.update(elapsed);

		// update camera position
		// _cameraPos.x = 500 * Math.sin(_cumTime * 0.001);
		// _cameraPos.z = 500 * Math.cos(_cumTime * 0.001);

		// process gamepad input if any
		// gameInput_APressed();
	}

	/**
	 * Render the scene for this frame. Assumes that `update` has already been called.
	 */
	public function render():Void
	{
		var context = stage.context3D;

		context.clear();
		context.setDepthTest(true, Context3DCompareMode.LESS);

		context.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);

		// Render scene - iterate all objects and render them
		var lookAtMat = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
		// var lookAtMat = createLookAtMatrix(_cameraPos, _target, _worldUp);
		lookAtMat.append(projectionTransform);
		_rubiksCube.render(lookAtMat);

		// ------ finish iteration
		context.present();
	}

	function next_operation(event:OperationCompleteEvent):Void
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
	 * Handle the addition of a new game input device (gamepad).
	 * 
	 * @param event the triggering event
	 */
	function gameInput_onDeviceAdded(event:GameInputEvent):Void
	{
		var device = event.device;
		trace('adding device = ${device.id}');
		for (cId in 0...device.numControls)
		{
			var ctl = device.getControlAt(cId);
			ctl.addEventListener(Event.CHANGE, gameInput_onChange);
			trace('ctl=${ctl.id}');
		}

		device.enabled = true;
		_gamepads.push(device);
	}

	/**
	 * Handle the removal of a game input device (gamepad).
	 * 
	 * @param event 
	 */
	private function gameInput_onDeviceRemoved(event:GameInputEvent):Void
	{
		var device = event.device;
		device.enabled = false;
		_gamepads.remove(device);
	}

	/**
	 * Process gamepad input
	 * @param e event container the changes in the control
	 */
	function gameInput_onChange(e:Event):Void
	{
		trace('evt target=${e.target}');
		var gic = cast(e.target, GameInputControl);
		trace('ctl=${gic.id} value = ${gic.value}');
		switch (gic.id)
		{
			case 'BUTTON_0':
				trace('A hit');
			case 'BUTTON_1':
				trace('B hit');
			case 'BUTTON_2':
				trace('X hit');
			case 'BUTTON_3':
				trace('Y hit');
			case 'BUTTON_4':
				trace('View hit');
			case 'BUTTON_5':
				trace('UNUSED hit');
			case 'BUTTON_6':
				trace('Menu hit');
			case 'BUTTON_7':
				trace('Left Stick Button hit');
			// go clockwise about y
			case 'BUTTON_8':
				trace('Right Stick Button hit');
			// go counterclockwise about y
			case 'BUTTON_9':
				trace('Left bumper hit');
			case 'BUTTON_10':
				trace('Right bumper hit');
			case 'BUTTON_11':
				trace('DPAD Up hit');
			case 'BUTTON_12':
				trace('DPAD Down hit');
			case 'BUTTON_13':
				trace('DPAD Left hit');
			case 'BUTTON_14':
				trace('DPAD Right hit');
			case 'AXIS_0':
				trace('Left Stick Horizontal Axis hit');
			case 'AXIS_1':
				trace('Left Stick Vertical Axis hit');
			case 'AXIS_2':
				trace('Right Stick Horizontal Axis hit');
			case 'AXIS_3':
				trace('Right Stick Vertical Axis hit');
			case 'AXIS_4':
				trace('Left trigger hit');
			case 'AXIS_5':
				trace('Right trigger hit');
			default:
				trace('${gic.id} UNKNOWN hit');
		}
	}

	function mouse_onMove(e:MouseEvent):Void
	{
		if (_firstMove)
		{
			_mouseX = e.localX;
			_mouseY = e.localY;
			_firstMove = false;
		}

		var deltaX = (e.localX - _mouseX) * SENSITIVITY;
		var deltaY = (_mouseY - e.localY) * SENSITIVITY;
		trace('mouse is at (${e.localX}, ${e.localY})');
		trace('delta = (${deltaX}, ${deltaY})');
		_mouseX = e.localX;
		_mouseY = e.localY;

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

		var direction = new Vector3D();
		direction.x = Math.cos(radians(_yaw)) * Math.cos(radians(_pitch));
		direction.y = Math.sin(radians(_pitch));
		direction.z = Math.sin(radians(_yaw)) * Math.cos(radians(_pitch));
		direction.normalize();
		_cameraFront = direction;
		trace('_cameraFront=${_cameraFront}');
	}

	function mouse_onWheel(e:MouseEvent):Void
	{
		_cameraFOV -= e.delta;
		if (_cameraFOV < 1.0)
		{
			_cameraFOV = 1.0;
		}
		if (_cameraFOV > 45)
		{
			_cameraFOV = 45;
		}
		projectionTransform = createPerspectiveProjection(_cameraFOV, 640 / 480, 100, 1000);
	}
}
