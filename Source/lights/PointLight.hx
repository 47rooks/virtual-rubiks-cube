package lights;

import lime.graphics.WebGL2RenderContext;
import lime.math.RGBA;
import lime.utils.Float32Array;
import models.Light;
import openfl.geom.Matrix3D;
import ui.UI;

/**
 * A point light supporting attentuation and position.
 */
class PointLight
{
	var _model:Light;

	public var position(default, null):Float32Array;

	// Attenuation constants
	var _constant:Float;
	var _linear:Float;
	var _quadratic:Float;

	/**
	 * Constructor
	 * @param position position of the light in world coordinates
	 * @param color display color of the light
	 * @param gl The WebGL render context
	 */
	public function new(position:Float32Array, color:RGBA, gl:WebGL2RenderContext)
	{
		this.position = position;
		_model = new Light(position, color, gl);
	}

	public function render(gl:WebGL2RenderContext, projectionMatrix:Matrix3D, ui:UI):Void
	{
		_model.render(gl, projectionMatrix, ui);
	}
}
