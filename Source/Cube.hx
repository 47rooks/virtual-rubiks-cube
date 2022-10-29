package;

import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.math.RGBA;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;

typedef ColorSpec =
{
	var top:RGBA;
	var bottom:RGBA;
	var left:RGBA;
	var right:RGBA;
	var front:RGBA;
	var back:RGBA;
}

/**
 * The basic unit cube centered at (0, 0, 0).
 */
class Cube
{
	// GL variables
	var _glInitialized = false;
	var _glVertexBuffer:GLBuffer;

	public var vertexData:Float32Array;
	public var indexData:Int32Array;

	private var _texture:RectangleTexture;
	private var _color:ColorSpec;

	public var bitmapIndexBuffer(default, null):IndexBuffer3D;
	public var bitmapVertexBuffer(default, null):VertexBuffer3D;

	// public function new(_color:ColorSpec, texture:RectangleTexture, context:Context3D)
	public function new(color:ColorSpec, texture:RectangleTexture)
	{
		// Load shaders from files
		// var vertex = Assets.getText("assets/cube.vert");
		// var fragment = Assets.getText("assets/cube.frag");
		// Create vertex data, including position, texture mapping and colour values.

		_texture = texture;
		_color = color;
		initializeData();
	}

	function initializeData():Void
	{
		if (!_glInitialized)
		{
			final side = 1.0;
			// var vertexData = new Vector<Float>([ // X, Y, Z                        U, V   R, G, B, A

			var v:Array<Float> = [ // X, Y, Z                        U, V   R, G, B, A
				side / 2.0,
				side / 2,
				-side / 2,
				0,
				1,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a, // Back
				- side / 2,
				side / 2,
				-side / 2,
				1,
				1,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a,
				-side / 2,
				-side / 2,
				-side / 2,
				1,
				0,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a,
				side / 2,
				-side / 2,
				-side / 2,
				0,
				0,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a,
				-side / 2,
				side / 2,
				-side / 2,
				0,
				1,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a, // Left
				- side / 2,
				side / 2,
				side / 2,
				1,
				1,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a,
				-side / 2,
				-side / 2,
				side / 2,
				1,
				0,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a,
				-side / 2,
				-side / 2,
				-side / 2,
				0,
				0,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a,
				-side / 2,
				side / 2,
				side / 2,
				0,
				1,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a, // Front
				side / 2,
				side / 2,
				side / 2,
				1,
				1,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a,
				side / 2,
				-side / 2,
				side / 2,
				1,
				0,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a,
				-side / 2,
				-side / 2,
				side / 2,
				0,
				0,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a,
				side / 2,
				side / 2,
				-side / 2,
				1,
				1,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a, // Right
				side / 2,
				side / 2,
				side / 2,
				0,
				1,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a,
				side / 2,
				-side / 2,
				side / 2,
				0,
				0,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a,
				side / 2,
				-side / 2,
				-side / 2,
				1,
				0,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a,
				side / 2,
				-side / 2,
				side / 2,
				1,
				0,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a, // Bottom
				- side / 2,
				-side / 2,
				side / 2,
				1,
				1,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a,
				-side / 2,
				-side / 2,
				-side / 2,
				0,
				1,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a,
				side / 2,
				-side / 2,
				-side / 2,
				0,
				0,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a,
				side / 2,
				side / 2,
				-side / 2,
				1,
				0,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a, // Top
				side / 2,
				side / 2,
				side / 2,
				0,
				0,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a,
				-side / 2,
				side / 2,
				side / 2,
				0,
				1,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a,
				-side / 2,
				side / 2,
				-side / 2,
				1,
				1,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a
			];
			vertexData = new Float32Array(v);

			// AGAL
			// bitmapVertexBuffer = context.createVertexBuffer(24, 9);
			// bitmapVertexBuffer.uploadFromVector(vertexData, 0, 24); // was 216

			// GL
			// _glVertexBuffer = gl.createBuffer();
			// gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
			// gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW);
			// gl.bindBuffer(gl.ARRAY_BUFFER, null);

			// Index for each cube face using the the vertex data above
			indexData = new Int32Array([
				 0,  1,    2, // Back
				 2,  0,           3,
				 4,  5,    6, // Left
				 4,  6,           7,
				 8,  9,  10, // Front
				10, 11,           8,
				12, 13,  15, // Right
				15, 13,          14,
				16, 17, 18, // Bottom
				16, 18,          19,
				20, 21,    22, // Top
				22, 23,          20
			]);

			// AGAL
			// bitmapIndexBuffer = context.createIndexBuffer(36);
			// bitmapIndexBuffer.uploadFromVector(indexData, 0, 36);
			_glInitialized = true;
		}
	}

	public function update():Void {}

	public function render(gl:WebGLRenderContext):Void {}
}
