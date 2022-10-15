package;

import MatrixUtils.createLookAtMatrix;
import MatrixUtils.computePerspectiveProjection;
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

	private var cacheTime:Int;

	var _rubiksCube:RubiksCube;

	var operations:Array<Operation>;
	var operNum:Int;

	var _bg:BitmapData;

	// Camera and world vectors
	var _cameraPos:Vector3D;
	var _target:Vector3D;
	var _worldUp:Vector3D;

	public function new():Void
	{
		super();

		// Initialize key fields
		_cameraPos = new Vector3D(500, 500, 500);
		_target = new Vector3D(0, 0, 0);
		_worldUp = new Vector3D(0, 1, 0);

		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
	}

	function addedToStage(e:Event):Void
	{
		// _bg = Assets.getBitmapData('assets/openfl.png');

		var context = stage.context3D;
		// computeOrthoProjection();
		// projectionTransform = computeOrthoProjection(-300.0, 300.0, 300.0, -300.0, 750.0, 1002.0);
		projectionTransform = computePerspectiveProjection(-320, 320, 240, -240, 600, 1200.0);
		_rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this);
		// _rubiksCube = new RubiksCube(context, 300, Math.ceil(stage.stageHeight / 2), 400, this);
		// addChild(new Bitmap(_bg));

		// Add completion event listener
		addEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, next_operation);

		// Add key listener to start example rotations
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		// Setup the operations
		operations = new Array<Operation>();
		operNum = 0;
	}

	/**
	 * Handle key press events
	 * @param event 
	 */
	function keyHandler(event:KeyboardEvent):Void
	{
		trace('key=${event.keyCode}');
		if (event.keyCode == Keyboard.S)
		{
			// Perform rotation operation on a slice.
			operations = new Array<Operation>();
			operations.push(Operation.RotateSlice(Axis.X, 1, 90));
			operations.push(Operation.RotateSlice(Axis.Y, 1, 90));
			operations.push(Operation.RotateSlice(Axis.Z, 1, 90));
			_rubiksCube.doOperation(operations[0]);
			operNum = 0;
		}
		else if (event.keyCode == Keyboard.P)
		{
			// Dump matrix transformation of cube vertices
			_rubiksCube.dumpTransformVertices(createLookAtMatrix(_cameraPos, _target, _worldUp));
		}
	}

	public function update(elapsed:Float):Void
	{
		_rubiksCube.update(0.016);
	}

	/* Render the current state */
	public function render():Void
	{
		var context = stage.context3D;

		context.clear();
		context.setDepthTest(true, Context3DCompareMode.LESS);

		context.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);

		// Render scene
		// FIXME call render on the scene
		var lookAtMat = createLookAtMatrix(_cameraPos, _target, _worldUp);
		lookAtMat.append(projectionTransform);
		_rubiksCube.render(lookAtMat);
		// _rubiksCube.render(projectionTransform);

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
}
