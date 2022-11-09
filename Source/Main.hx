package;

import lime.graphics.WebGLRenderContext;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.RenderEvent;

class Main extends Sprite
{
	private var cacheTime:Int;

	var _scene:Scene;

	var added = false;

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

		addChild(_scene);
	}

	function resize(width:Int, height:Int):Void
	{
		// FIXME call scene resize
	}

	// Event Handlers

	function stage_onRender(event:RenderEvent):Void
	{
		var renderer:OpenGLRenderer = cast event.renderer;
		renderer.setShader(null);
		var gl:WebGLRenderContext = renderer.gl;
		_scene.render(gl);

		// if (!added)
		// {
		// 	var image = Assets.getBitmapData("assets/openfl.png");

		// 	var bitmap = new Bitmap(image);
		// 	bitmap.x = 20;
		// 	bitmap.y = 20;
		// 	addChild(bitmap);
		// 	added = true;
		// }
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
