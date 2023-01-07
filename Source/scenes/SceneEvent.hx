package scenes;

import openfl.events.Event;

/**
 * Custom event to indicate scene operations.
 */
class SceneEvent extends Event
{
	/**
	 * Scene's intialization about to start.
	 */
	public static final SCENE_INITIALIZATION_BEGIN = "scene_initialization_begin";

	/**
	 * Scene first render completed - at this point the scene is fully initialized and should be displayed.
	 */
	public static final SCENE_INITIAL_RENDER_END = "scene_initial_render_end";

	/**
	 * Constructor
	 * @param type event type
	 * @param bubbles whether the event bubbles
	 * @param cancelable whether the event is cancelable
	 */
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false)
	{
		super(type, bubbles, cancelable);
	}

	public override function clone():SceneEvent
	{
		return new SceneEvent(type, bubbles, cancelable);
	}

	public override function toString():String
	{
		return "[SceneEvent type=\"" + type + "\" bubbles=" + bubbles + " cancelable=" + cancelable + " eventPhase=" + eventPhase + "]";
	}
}
