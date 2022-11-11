package;

import haxe.ui.Toolkit;
import lime.graphics.WebGLRenderContext;
import openfl.Lib;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.RenderEvent;
import openfl.ui.Keyboard;
import openfl.ui.Mouse;

class Main extends Sprite
{
	private var cacheTime:Int;

	var _scene:Scene;

	// UI Variables
	var _ui:UI;
	var _mouseVisible:Bool;

	public function new()
	{
		super();

		/// AGAL
		// var context = stage.context3D;

		// if (context == null)
		// {
		// 	trace("Stage does not have a compatible 3D context available");
		// 	return;
		// }

		_scene = new Scene();

		// Add event handlers
		stage.addEventListener(Event.RESIZE, stage_onResize);
		stage.addEventListener(RenderEvent.RENDER_OPENGL, stage_onRender); // FIXME rename cbk
		stage.addEventListener(Event.ENTER_FRAME, stage_onEnterFrame);

		// Add key listener
		// FIXME This is a problem as we have two handlers. I need to figure out how to make sure there are
		//       no duplicate mappings.
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		addChild(_scene);

		// Create UI
		Toolkit.init();
		_ui = new UI();
		addChild(_ui);

		_mouseVisible = false;
	}

	function keyHandler(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.H:
				_ui.toggleVisibility();
				_scene.toggleControls();
				if (_mouseVisible)
				{
					Mouse.hide();
					_mouseVisible = false;
				}
				else
				{
					Mouse.show();
					_mouseVisible = true;
				}
			default:
		}
	}

	function resize(width:Int, height:Int):Void
	{
		// FIXME call scene resize
	}

	// Event Handlers
	// FIXME This could be driven from the scene level - should it be ?
	function stage_onRender(event:RenderEvent):Void
	{
		var renderer:OpenGLRenderer = cast event.renderer;
		renderer.setShader(null);
		var gl:WebGLRenderContext = renderer.gl;
		_scene.render(_ui);
	}

	function stage_onResize(event:Event):Void
	{
		resize(stage.stageWidth, stage.stageHeight);
	}

	function stage_onEnterFrame(event:Event):Void
	{
		// Get elapsed time and update the angle
		var newTime = Lib.getTimer(); // ms
		var elapsed = newTime - cacheTime; // ms elapsed
		cacheTime = newTime;

		// update current state
		_scene.update(elapsed);

		// Now render - invalidating the stage will cause the render event to fire
		//  which will trigger the stage_onRender() callback.
		stage.invalidate();
	}
}
