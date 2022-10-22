package;

import openfl.events.Event;

/**
 * Custom event to indicate completion of a cube operation.
 */
class OperationCompleteEvent extends Event
{
	public static var OPERATION_COMPLETE_EVENT = "RubiksCubeOperationComplete";

	public var customData:Int;

	/**
	 * Constructor
	 * @param type event type
	 * @param customData custom data for the event
	 * @param bubbles whether the event bubbles
	 * @param cancelable whether the event is cancelable
	 */
	public function new(type:String, customData:Int, bubbles:Bool = false, cancelable:Bool = false)
	{
		this.customData = customData;
		super(type, bubbles, cancelable);
	}

	public override function clone():OperationCompleteEvent
	{
		return new OperationCompleteEvent(type, customData, bubbles, cancelable);
	}

	public override function toString():String
	{
		return "[OperationCompleteEvent type=\"" + type + "\" bubbles=" + bubbles + " cancelable=" + cancelable + " eventPhase=" + eventPhase
			+ " customData=" + customData + "]";
	}
}
