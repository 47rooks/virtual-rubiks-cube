package;

import Camera.CameraMovement;
import MatrixUtils.createPerspectiveProjection;
import RubiksCube.Axis;
import RubiksCube.Operation;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display3D.Context3DCompareMode;
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

class Scene extends Sprite
{
	private var projectionTransform:Matrix3D;

	private var _deltaTime:Float;

	var _rubiksCube:RubiksCube;

	var operations:Array<Operation>;
	var operNum:Int;

	var _bg:BitmapData;

	// Camera
	var _camera:Camera;

	// Gamepad input
	var _gameInput:GameInput;
	var _gamepads:Array<GameInputDevice>;

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
		// projectionTransform = createPerspectiveProjection(_cameraFOV, 640 / 480, 100, 1000);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		_rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this);
		// _rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), 0, this);
		// _rubiksCube = new RubiksCube(context, 300, Math.ceil(stage.stageHeight / 2), 400, this);
		// addChild(new Bitmap(_bg));

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
	 * Handle key press events
	 * 
	 * @param event keyboard event
	 */
	function keyHandler(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
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
	 * Update the current state.
	 * 
	 * @param elapsed elapsed time since last call.
	 */
	public function update(elapsed:Float):Void
	{
		_deltaTime = elapsed / 1000.0;

		_rubiksCube.update(elapsed);
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
		// var lookAtMat = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
		var lookAtMat = _camera.getViewMatrix();
		// var lookAtMat = createLookAtMatrix(_cameraPos, _target, _worldUp);
		lookAtMat.append(projectionTransform);
		_rubiksCube.render(lookAtMat);

		// ------ finish iteration
		context.present();
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
	 * Handle the addition of a new game input device (gamepad).
	 * 
	 * @param event the triggering event
	 */
	function gameInputOnDeviceAdded(event:GameInputEvent):Void
	{
		var device = event.device;
		trace('adding device = ${device.id}');
		for (cId in 0...device.numControls)
		{
			var ctl = device.getControlAt(cId);
			ctl.addEventListener(Event.CHANGE, gameInputOnChange);
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

		_camera.lookAround(e.localX - _mouseX, _mouseY - e.localY);
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
}
