package ui;

import haxe.ui.components.Slider;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;

using StringTools;

/**
 * A LabelledSlider labels the min, max and current value of the slider. It
 * also supports scaling the limits so that ranges between 0.0 and 1.0 work
 * properly.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/ui/labelled-slider.xml"))
class LabelledSlider extends VBox
{
	@:bind(lsNameId.text) public var title:String;

	@:isVar public var min(get, set):Float;

	function get_min()
	{
		return lsSliderId.min / scale;
	}

	function set_min(v:Float):Float
	{
		lsSliderId.min = v * scale;
		return lsSliderId.min / scale;
	}

	@:isVar public var max(get, set):Float;

	function get_max()
	{
		return lsSliderId.max / scale;
	}

	function set_max(v:Float):Float
	{
		lsSliderId.max = v * scale;
		return lsSliderId.max / scale;
	}

	@:isVar public var pos(get, set):Float;

	function get_pos()
	{
		return lsSliderId.pos / scale;
	}

	function set_pos(v:Float):Float
	{
		lsSliderId.pos = v * scale;
		return lsSliderId.pos / scale;
	}

	@:isVar public var step(get, set):Float;

	function get_step()
	{
		return step;
	}

	function set_step(v:Float):Float
	{
		lsSliderId.step = v * scale;
		return step;
	}

	public var scale:Float = 1.0;
	public var thumbPrecision:Int = 0;
	public var minMaxPrecision:Int = 0;

	/**
	 * Format a float to a specified number of decimal places.
	 * Will handle scientific notification formatting the 
	 * mantissa but not the exponent.
	 * @param v the value to format
	 * @param precision the number of decimal places
	 * @return String
	 */
	private function formatFloat(v:Float, precision:Int):String
	{
		var s = '${v}';
		var mantissa = '';
		var exponent = '';
		if (s.contains('e'))
		{
			mantissa = s.substr(0, s.indexOf('e'));
			exponent = s.substr(s.indexOf('e'));
			s = mantissa;
		}
		if (!s.contains('.'))
		{
			s = s + '.';
		}
		var decLoc = s.indexOf('.');
		var lenToRtn = decLoc + precision + 1;
		if (s.length > lenToRtn)
		{
			return s.substr(0, lenToRtn) + exponent;
		}
		return s.rpad('0', lenToRtn) + exponent;
	}

	/**
	 * Set the initial label values when the component is ready.
	 */
	override public function onReady()
	{
		super.onReady();
		lsMaxId.text = formatFloat(lsSliderId.max / scale, minMaxPrecision);
		lsMinId.text = formatFloat(lsSliderId.min / scale, minMaxPrecision);
		lsCurValueId.text = formatFloat(lsSliderId.pos / scale, thumbPrecision);
	}

	/**
	 * Update the label for the current position.
	 * @param e the property change event.
	 */
	@:bind(lsSliderId, UIEvent.PROPERTY_CHANGE)
	function onSliderChange(e:UIEvent)
	{
		var o = cast(e.target, Slider);
		if (e.data == 'pos' && o.value)
		{
			lsCurValueId.text = formatFloat(o.value / scale, thumbPrecision);
		}
	}
}
