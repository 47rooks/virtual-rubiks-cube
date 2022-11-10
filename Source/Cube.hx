package;

import lime.graphics.opengl.GLUniformLocation;
import lime.math.RGBA;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;

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
	// Model data
	public var vertexData:Vector<Float>;
	public var indexData:Vector<UInt>;

	// GL interface variables
	public var _glVertexBuffer:VertexBuffer3D;
	public var _glIndexBuffer:IndexBuffer3D;

	private var _programMatrixUniform:GLUniformLocation;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	private var _glInitialized = false;

	private var _color:ColorSpec;

	public function new(color:ColorSpec, context:Context3D)
	{
		// Load shaders from files
		// var vertex = Assets.getText("assets/cube.vert");
		// var fragment = Assets.getText("assets/cube.frag");
		// Create vertex data, including position, texture mapping and colour values.

		_color = color;
		initializeGl(context);
	}

	function initializeGl(context:Context3D):Void
	{
		final side = 1.0;

		var v = [ // X, Y, Z                        U, V   R, G, B, A
			side / 2.0,
			side / 2,
			-side / 2,
			0,
			0,
			_color.back.r,
			_color.back.g,
			_color.back.g,
			_color.back.a,
			0.0,
			0.0,
			-1.0, // Back
			- side / 2,
			side / 2,
			-side / 2,
			1,
			0,
			_color.back.r,
			_color.back.g,
			_color.back.g,
			_color.back.a,
			0.0,
			0.0,
			-1.0,
			-side / 2,
			-side / 2,
			-side / 2,
			1,
			1,
			_color.back.r,
			_color.back.g,
			_color.back.g,
			_color.back.a,
			0.0,
			0.0,
			-1.0,
			side / 2,
			-side / 2,
			-side / 2,
			0,
			1,
			_color.back.r,
			_color.back.g,
			_color.back.g,
			_color.back.a,
			0.0,
			0.0,
			-1.0,
			-side / 2,
			side / 2,
			-side / 2,
			0,
			0,
			_color.left.r,
			_color.left.g,
			_color.left.b,
			_color.left.a,
			-1.0,
			0.0,
			0.0, // Left
			- side / 2,
			side / 2,
			side / 2,
			1,
			0,
			_color.left.r,
			_color.left.g,
			_color.left.b,
			_color.left.a,
			-1.0,
			0.0,
			0.0,
			-side / 2,
			-side / 2,
			side / 2,
			1,
			1,
			_color.left.r,
			_color.left.g,
			_color.left.b,
			_color.left.a,
			-1.0,
			0.0,
			0.0,
			-side / 2,
			-side / 2,
			-side / 2,
			0,
			1,
			_color.left.r,
			_color.left.g,
			_color.left.b,
			_color.left.a,
			-1.0,
			0.0,
			0.0,
			-side / 2,
			side / 2,
			side / 2,
			0,
			0,
			_color.front.r,
			_color.front.g,
			_color.front.b,
			_color.front.a,
			0.0,
			0.0,
			1.0, // Front
			side / 2,
			side / 2,
			side / 2,
			1,
			0,
			_color.front.r,
			_color.front.g,
			_color.front.b,
			_color.front.a,
			0.0,
			0.0,
			1.0,
			side / 2,
			-side / 2,
			side / 2,
			1,
			1,
			_color.front.r,
			_color.front.g,
			_color.front.b,
			_color.front.a,
			0.0,
			0.0,
			1.0,
			-side / 2,
			-side / 2,
			side / 2,
			0,
			1,
			_color.front.r,
			_color.front.g,
			_color.front.b,
			_color.front.a,
			0.0,
			0.0,
			1.0,
			side / 2,
			side / 2,
			-side / 2,
			1,
			0,
			_color.right.r,
			_color.right.g,
			_color.right.b,
			_color.right.a,
			1.0,
			0.0,
			0.0, // Right
			side / 2,
			side / 2,
			side / 2,
			0,
			0,
			_color.right.r,
			_color.right.g,
			_color.right.b,
			_color.right.a,
			1.0,
			0.0,
			0.0,
			side / 2,
			-side / 2,
			side / 2,
			0,
			1,
			_color.right.r,
			_color.right.g,
			_color.right.b,
			_color.right.a,
			1.0,
			0.0,
			0.0,
			side / 2,
			-side / 2,
			-side / 2,
			1,
			1,
			_color.right.r,
			_color.right.g,
			_color.right.b,
			_color.right.a,
			1.0,
			0.0,
			0.0,
			side / 2,
			-side / 2,
			side / 2,
			0,
			0,
			_color.bottom.r,
			_color.bottom.g,
			_color.bottom.b,
			_color.bottom.a,
			0.0,
			-1.0,
			0.0, // Bottom
			- side / 2,
			-side / 2,
			side / 2,
			0,
			1,
			_color.bottom.r,
			_color.bottom.g,
			_color.bottom.b,
			_color.bottom.a,
			0.0,
			-1.0,
			0.0,
			-side / 2,
			-side / 2,
			-side / 2,
			1,
			1,
			_color.bottom.r,
			_color.bottom.g,
			_color.bottom.b,
			_color.bottom.a,
			0.0,
			-1.0,
			0.0,
			side / 2,
			-side / 2,
			-side / 2,
			1,
			0,
			_color.bottom.r,
			_color.bottom.g,
			_color.bottom.b,
			_color.bottom.a,
			0.0,
			-1.0,
			0.0,
			side / 2,
			side / 2,
			-side / 2,
			0,
			0,
			_color.top.r,
			_color.top.g,
			_color.top.b,
			_color.top.a,
			0.0,
			1.0,
			0.0, // Top
			side / 2,
			side / 2,
			side / 2,
			1,
			0,
			_color.top.r,
			_color.top.g,
			_color.top.b,
			_color.top.a,
			0.0,
			1.0,
			0.0,
			-side / 2,
			side / 2,
			side / 2,
			1,
			1,
			_color.top.r,
			_color.top.g,
			_color.top.b,
			_color.top.a,
			0.0,
			1.0,
			0.0,
			-side / 2,
			side / 2,
			-side / 2,
			0,
			1,
			_color.top.r,
			_color.top.g,
			_color.top.b,
			_color.top.a,
			0.0,
			1.0,
			0.0
		];
		vertexData = new Vector<Float>(v);
		// _glVertexBuffer = gl.createBuffer();
		// gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
		// gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW);
		_glVertexBuffer = context.createVertexBuffer(24, 12, STATIC_DRAW);
		_glVertexBuffer.uploadFromVector(vertexData, 0, 288);

		// Index for each cube face using the the vertex data above

		indexData = new Vector<UInt>([
			 2,  3,    0, // Back
			 0,  1,           2,
			10, 11,   9, // Front
			 8,  9,          11,
			 5,  4,    7, // Left
			 7,  6,           5,
			14, 15,  12, // Right
			12, 13,          14,
			18, 19, 16, // Bottom
			16, 17,          18,
			21, 20,    23, // Top
			21, 23,          22
		]);
		// _glIndexBuffer = gl.createBuffer();
		// gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _glIndexBuffer);
		// gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);
		_glIndexBuffer = context.createIndexBuffer(36, STATIC_DRAW);
		_glIndexBuffer.uploadFromVector(indexData, 0, 36);
	}
}
