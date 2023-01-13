package lights;

import lime.graphics.WebGLRenderContext;
import lime.utils.Float32Array;
import openfl.display3D.Context3D;

/**
 * A Flashlight is positioned at the viewer(camera) and points out.There is no
 * rendered model because standing with the viewer. 
 */
class Flashlight
{
	public var position(default, null):Float32Array;

	public var direction(default, null):Float32Array;

	public var cutoff(default, null):Float;

	public function new(initialPosition:Float32Array, initialDirection:Float32Array, initialCutoff:Float, gl:WebGLRenderContext, context:Context3D)
	{
		direction = initialDirection;
		cutoff = initialCutoff;
	}
}
