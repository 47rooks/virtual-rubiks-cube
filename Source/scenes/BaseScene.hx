package scenes;

import lime.graphics.WebGLRenderContext;
import lime.math.RGBA;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.events.Event;
import ui.UI;

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
	var _context:Context3D;

	// Control target - which object is controlled by the inputs
	var _controlTarget:ControlTarget;
	var _controlsEnabled:Bool;

	var _initialSceneRendered:Bool = false;

	/**
	 * Constructor
	 * @param ui the UI instance
	 */
	public function new(ui:UI)
	{
		super();

		_ui = ui;
		_controlsEnabled = !_ui.isVisible;

		addEventListener(Event.ADDED_TO_STAGE, sceneAddedToStage);
	}

	/**
	 * Close the scene unregistering any event listeners and deallocating resources which cannot be cleaned up just by freeing the scene object.
	 */
	abstract function close():Void;

	public function closeScene():Void
	{
		close();
	}

	/**
	 * Update any scene state for this frame.
	 * @param elapsed time since the last update
	 */
	abstract function update(elapsed:Float):Void;

	public function updateScene(elapsed:Float):Void
	{
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
		_context = stage.context3D;

		// Register initial scene render completed handler
		// addEventListener(SceneEvent.SCENE_INITIAL_RENDER_END, _ui.clearSceneLoadingMessage);

		// Notify current scene
		addedToStage(e);

		removeEventListener(Event.ADDED_TO_STAGE, sceneAddedToStage);
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
		_gl.disable(_gl.STENCIL_TEST);
		_gl.clear(_gl.COLOR_BUFFER_BIT | _gl.DEPTH_BUFFER_BIT | _gl.STENCIL_BUFFER_BIT);
		_gl.depthFunc(_gl.LESS);
		_gl.depthMask(true);
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
}
