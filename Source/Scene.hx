package;

import RubiksCube.Operation;
import openfl.events.Event;
import openfl.Vector;
import RubiksCube.Axis;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.Matrix3D;
import openfl.display.Sprite;

class Scene extends Sprite {

	private var projectionTransform:Matrix3D;

	private var cacheTime:Int;

	var rubiksCube:RubiksCube;

    var operations:Array<Operation>;
    var operNum:Int;

    public function new():Void {
        super();

        addEventListener(Event.ADDED_TO_STAGE, addedToStage);
    }

    function addedToStage(e:Event):Void {
		var context = stage.context3D;
		computeProjection();

		rubiksCube = new RubiksCube(context, Math.ceil(stage.stageWidth /2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this);

        // Add completion event listener
        addEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, next_operation);
	
        // Setup the operations
        operations = new Array<Operation>();
        operations.push(Operation.RotateSlice(Axis.X, 1, 90));
        operations.push(Operation.RotateSlice(Axis.Y, 1, -90));
        operations.push(Operation.RotateSlice(Axis.Z, 1, 90));
        rubiksCube.doOperation(operations[0]);
        operNum = 0;
    }

	function computeProjection():Void {
		projectionTransform = new Matrix3D();
		projectionTransform.copyRawDataFrom (Vector.ofArray ([
			2.0 / stage.stageWidth, 0.0, 0.0, 0.0,
			0.0, -2.0 / stage.stageHeight, 0.0, 0.0,
			0.0, 0.0, -2.0 / 2000, 0.0,
			-1.0, 1.0, 0.0, 1.0
		]));
	}

    public function update(elapsed:Float):Void {
		rubiksCube.update(0.016);
    }

    /* Render the current state */
	public function render():Void {

		var context = stage.context3D;

		context.clear();
		context.setDepthTest(true, Context3DCompareMode.LESS);

		context.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);

		// Render scene
		// FIXME call render on the scene
		rubiksCube.render(projectionTransform);

		// ------ finish iteration
		context.present ();
	}

    function next_operation(event:OperationCompleteEvent):Void {
        trace('operation completed');
        if (operNum < operations.length - 1) {
            rubiksCube.doOperation(operations[++operNum]);
        } else {
            trace('completed last operation');
        }
    }
}