package;

import lime.math.RGBA;
import openfl.Vector;
import openfl.display3D.Context3D;
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
	private var _texture:RectangleTexture;

	public var bitmapIndexBuffer(default, null):IndexBuffer3D;
	public var bitmapVertexBuffer(default, null):VertexBuffer3D;

	public function new(color:ColorSpec, texture:RectangleTexture, context:Context3D)
	{
		// Load shaders from files
		// var vertex = Assets.getText("assets/cube.vert");
		// var fragment = Assets.getText("assets/cube.frag");
		// Create vertex data, including position, texture mapping and colour values.

		_texture = texture;
		final side = 1.0;
		var vertexData = new Vector<Float>([ // X, Y, Z                        U, V   R, G, B, A
			side / 2,
			side / 2,
			-side / 2,
			0,
			1,
			color.back.r,
			color.back.g,
			color.back.g,
			color.back.a, // Back
			- side / 2,
			side / 2,
			-side / 2,
			1,
			1,
			color.back.r,
			color.back.g,
			color.back.g,
			color.back.a,
			-side / 2,
			-side / 2,
			-side / 2,
			1,
			0,
			color.back.r,
			color.back.g,
			color.back.g,
			color.back.a,
			side / 2,
			-side / 2,
			-side / 2,
			0,
			0,
			color.back.r,
			color.back.g,
			color.back.g,
			color.back.a,

			-side / 2,
			side / 2,
			-side / 2,
			0,
			1,
			color.left.r,
			color.left.g,
			color.left.b,
			color.left.a, // Left
			- side / 2,
			side / 2,
			side / 2,
			1,
			1,
			color.left.r,
			color.left.g,
			color.left.b,
			color.left.a,
			-side / 2,
			-side / 2,
			side / 2,
			1,
			0,
			color.left.r,
			color.left.g,
			color.left.b,
			color.left.a,
			-side / 2,
			-side / 2,
			-side / 2,
			0,
			0,
			color.left.r,
			color.left.g,
			color.left.b,
			color.left.a,

			-side / 2,
			side / 2,
			side / 2,
			0,
			1,
			color.front.r,
			color.front.g,
			color.front.b,
			color.front.a, // Front
			side / 2,
			side / 2,
			side / 2,
			1,
			1,
			color.front.r,
			color.front.g,
			color.front.b,
			color.front.a,
			side / 2,
			-side / 2,
			side / 2,
			1,
			0,
			color.front.r,
			color.front.g,
			color.front.b,
			color.front.a,
			-side / 2,
			-side / 2,
			side / 2,
			0,
			0,
			color.front.r,
			color.front.g,
			color.front.b,
			color.front.a,

			side / 2,
			side / 2,
			-side / 2,
			1,
			1,
			color.right.r,
			color.right.g,
			color.right.b,
			color.right.a, // Right
			side / 2,
			side / 2,
			side / 2,
			0,
			1,
			color.right.r,
			color.right.g,
			color.right.b,
			color.right.a,
			side / 2,
			-side / 2,
			side / 2,
			0,
			0,
			color.right.r,
			color.right.g,
			color.right.b,
			color.right.a,
			side / 2,
			-side / 2,
			-side / 2,
			1,
			0,
			color.right.r,
			color.right.g,
			color.right.b,
			color.right.a,

			side / 2,
			-side / 2,
			side / 2,
			1,
			0,
			color.bottom.r,
			color.bottom.g,
			color.bottom.b,
			color.bottom.a, // Bottom
			- side / 2,
			-side / 2,
			side / 2,
			1,
			1,
			color.bottom.r,
			color.bottom.g,
			color.bottom.b,
			color.bottom.a,
			-side / 2,
			-side / 2,
			-side / 2,
			0,
			1,
			color.bottom.r,
			color.bottom.g,
			color.bottom.b,
			color.bottom.a,
			side / 2,
			-side / 2,
			-side / 2,
			0,
			0,
			color.bottom.r,
			color.bottom.g,
			color.bottom.b,
			color.bottom.a,

			side / 2,
			side / 2,
			-side / 2,
			1,
			0,
			color.top.r,
			color.top.g,
			color.top.b,
			color.top.a, // Top
			side / 2,
			side / 2,
			side / 2,
			0,
			0,
			color.top.r,
			color.top.g,
			color.top.b,
			color.top.a,
			-side / 2,
			side / 2,
			side / 2,
			0,
			1,
			color.top.r,
			color.top.g,
			color.top.b,
			color.top.a,
			-side / 2,
			side / 2,
			-side / 2,
			1,
			1,
			color.top.r,
			color.top.g,
			color.top.b,
			color.top.a
		]);

		bitmapVertexBuffer = context.createVertexBuffer(24, 9);
		bitmapVertexBuffer.uploadFromVector(vertexData, 0, 24); // was 216

		// Index for each cube face using the the vertex data above
		var indexData = new Vector<UInt>([
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
		bitmapIndexBuffer = context.createIndexBuffer(36);
		bitmapIndexBuffer.uploadFromVector(indexData, 0, 36);
	}

	public function update():Void {}

	public function render():Void {}
}
