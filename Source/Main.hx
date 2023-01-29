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
import scenes.BaseScene;
import scenes.BasicsScene;
import scenes.BlendingScene;
import scenes.CullingScene;
import scenes.FramebufferScene;
import scenes.ModelLoadingScene;
import scenes.StencilBufferScene;
import ui.UI;

/**
 * This is the main class which sets up both the 3D scene and the 2D UI objects.
 * It uses both the OpenFL renderer via the Context3D to manage uploading vertex attributes and textures,
 * and to make the 3D render draw call. All other GL interactions are done via the WebGL render context
 * which gives much greater control over GL operations and fully supports GLSL shader programs. This
 * approach allows support of the 2D HaxeUI and the 3D GL program for the Rubik's cube.
 */
class Main extends Sprite
{
	private var cacheTime:Int;

	var _sceneType:SceneType;
	var _scene:BaseScene;

	var _sceneInitialUpdateCalled:Bool = false;

	// UI Variables
	var _ui:UI;
	var _mouseVisible:Bool;

	public function new()
	{
		super();

		// Create UI
		Toolkit.init();
		_ui = new UI();

		_scene = new BasicsScene(_ui);
		_sceneType = SceneType.BASIC;

		// Add event handlers
		stage.addEventListener(Event.RESIZE, stage_onResize);
		stage.addEventListener(RenderEvent.RENDER_OPENGL, stage_onRender); // FIXME rename cbk
		stage.addEventListener(Event.ENTER_FRAME, stage_onEnterFrame);

		// Add key listener
		// FIXME This is a problem as we have two handlers. I need to figure out how to make sure there are
		//       no duplicate mappings.
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		addChild(_scene);
		addChild(_ui);

		_mouseVisible = false;
	}

	function keyHandler(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.H:
				_ui.toggleVisibility();
				_scene.setControlsEnabled(!_ui.isVisible);
				if (_mouseVisible)
				{
					Mouse.hide();
				}
				else
				{
					Mouse.show();
				}
				_mouseVisible = _ui.isVisible;
			default:
		}
	}

	function resize(width:Int, height:Int):Void
	{
		// FIXME call scene resize
	}

	// Event Handlers

	function stage_onEnterFrame(event:Event):Void
	{
		// Get elapsed time and update the angle
		var newTime = Lib.getTimer(); // ms
		var elapsed = newTime - cacheTime; // ms elapsed
		cacheTime = newTime;

		// If scene has changed create the new scene and close out the old one
		if (_sceneType != _ui.sceneType)
		{
			// Create the new scene
			var newScene:BaseScene;
			switch (_ui.sceneType)
			{
				case BASIC:
					{
						newScene = new BasicsScene(_ui);
					}
				case MODEL_LOADING:
					{
						newScene = new ModelLoadingScene(_ui);
					}
				case STENCIL:
					{
						newScene = new StencilBufferScene(_ui);
					}
				case BLENDING:
					{
						newScene = new BlendingScene(_ui);
					}
				case CULLING:
					{
						newScene = new CullingScene(_ui);
					}
				case FRAMEBUFFER:
					{
						newScene = new FramebufferScene(_ui);
					}
			}

			// Clean up and remove the old scene
			if (_scene != null)
			{
				// Clean up current scene resources
				_scene.closeScene();
				removeChild(_scene);
			}

			// Add the new scene
			_scene = newScene;
			_sceneType = _ui.sceneType;
			addChild(_scene);
			_sceneInitialUpdateCalled = false;

			// Return here so that the new scene can process the ADDED_TO_STAGE event
			return;
		}

		if (_scene.stage != null)
		{
			// update current state
			_scene.updateScene(elapsed);
			if (!_sceneInitialUpdateCalled)
			{
				_sceneInitialUpdateCalled = true;
			}
		}

		// Now render - invalidating the stage will cause the render event to fire
		//  which will trigger the stage_onRender() callback.
		stage.invalidate();
	}

	// FIXME This could be driven from the scene level - should it be ?
	function stage_onRender(event:RenderEvent):Void
	{
		var renderer:OpenGLRenderer = cast event.renderer;
		renderer.setShader(null);
		var gl:WebGLRenderContext = renderer.gl;

		// Make sure that at least one update() call occurs before render. This prevents calling the render
		// before the scene has had a chance to setup anything that is deferred to update().
		if (_sceneInitialUpdateCalled)
		{
			_scene.renderScene();
		}
	}

	function stage_onResize(event:Event):Void
	{
		resize(stage.stageWidth, stage.stageHeight);
	}
}
