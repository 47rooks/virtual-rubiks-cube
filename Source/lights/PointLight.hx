package lights;

import lime.graphics.WebGLRenderContext;
import lime.math.RGBA;
import lime.utils.Float32Array;
import models.Light;
import openfl.display3D.Context3D;
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
	 * @param context The OpenFL 3D render context.
	 */
	public function new(position:Float32Array, color:RGBA, gl:WebGLRenderContext, context:Context3D)
	{
		this.position = position;
		_model = new Light(position, color, gl, context);
	}

	public function render(gl:WebGLRenderContext, context:Context3D, projectionMatrix:Matrix3D, ui:UI):Void
	{
		_model.render(gl, context, projectionMatrix, ui);
	}
}
