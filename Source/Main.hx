package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite {
	
	private var cacheTime:Int;

	var _scene:Scene;

	public function new() {
		
		super ();
		
		var context = stage.context3D;
		
		if (context == null) {
			trace ("Stage does not have a compatible 3D context available");
			return;
		}
		
		_scene = new Scene();
		addChild(_scene);

		// Add event handlers
		stage.addEventListener(Event.RESIZE, stage_onResize);
		stage.addEventListener(Event.RENDER, stage_onRender);
		stage.addEventListener(Event.ENTER_FRAME, stage_onEnterFrame);
	}

	/* Render the current state */
	function render():Void {
		_scene.render();
	}
	
	
	function resize(width:Int, height:Int):Void {
		// FIXME call scene resize
	}
	
	// Event Handlers
	
	function stage_onRender(event:Event):Void {
		render();	
	}
	
	
	function stage_onResize(event:Event):Void {
		resize(stage.stageWidth, stage.stageHeight);
	}
	
	function stage_onEnterFrame(event:Event):Void {
		// Get elapsed time and update the angle
		var newTime = Lib.getTimer();   // ms
		var elapsed = newTime - cacheTime;  // ms elapsed

		// update current state
		_scene.update(elapsed);

		// Now render - invalidating the stage will cause the render event to fire
		//  which will trigger the stage_onRender() callback.
		stage.invalidate();
	}
	
}