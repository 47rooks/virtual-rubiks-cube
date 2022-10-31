package;

import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.RGBA;
import lime.utils.Float32Array;
import lime.utils.Int32Array;

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
	public var vertexData:Float32Array;
	public var indexData:Int32Array;

	// GL interface variables
	public var _glVertexBuffer:GLBuffer;
	public var _glIndexBuffer:GLBuffer;

	private var _programMatrixUniform:GLUniformLocation;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	private var _glInitialized = false;

	private var _color:ColorSpec;

	public function new(color:ColorSpec)
	{
		// Load shaders from files
		// var vertex = Assets.getText("assets/cube.vert");
		// var fragment = Assets.getText("assets/cube.frag");
		// Create vertex data, including position, texture mapping and colour values.

		_color = color;
	}

	function setupData(gl:WebGLRenderContext):Void
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
				0,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a, // Back
				- side / 2,
				side / 2,
				-side / 2,
				1,
				0,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a,
				-side / 2,
				-side / 2,
				-side / 2,
				1,
				1,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a,
				side / 2,
				-side / 2,
				-side / 2,
				0,
				1,
				_color.back.r,
				_color.back.g,
				_color.back.g,
				_color.back.a,
				-side / 2,
				side / 2,
				-side / 2,
				0,
				0,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a, // Left
				- side / 2,
				side / 2,
				side / 2,
				1,
				0,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a,
				-side / 2,
				-side / 2,
				side / 2,
				1,
				1,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a,
				-side / 2,
				-side / 2,
				-side / 2,
				0,
				1,
				_color.left.r,
				_color.left.g,
				_color.left.b,
				_color.left.a,
				-side / 2,
				side / 2,
				side / 2,
				0,
				0,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a, // Front
				side / 2,
				side / 2,
				side / 2,
				1,
				0,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a,
				side / 2,
				-side / 2,
				side / 2,
				1,
				1,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a,
				-side / 2,
				-side / 2,
				side / 2,
				0,
				1,
				_color.front.r,
				_color.front.g,
				_color.front.b,
				_color.front.a,
				side / 2,
				side / 2,
				-side / 2,
				1,
				0,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a, // Right
				side / 2,
				side / 2,
				side / 2,
				0,
				0,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a,
				side / 2,
				-side / 2,
				side / 2,
				0,
				1,
				_color.right.r,
				_color.right.g,
				_color.right.b,
				_color.right.a,
				side / 2,
				-side / 2,
				-side / 2,
				1,
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
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a, // Bottom
				- side / 2,
				-side / 2,
				side / 2,
				0,
				1,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a,
				-side / 2,
				-side / 2,
				-side / 2,
				1,
				1,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a,
				side / 2,
				-side / 2,
				-side / 2,
				1,
				0,
				_color.bottom.r,
				_color.bottom.g,
				_color.bottom.b,
				_color.bottom.a,
				side / 2,
				side / 2,
				-side / 2,
				0,
				0,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a, // Top
				side / 2,
				side / 2,
				side / 2,
				1,
				0,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a,
				-side / 2,
				side / 2,
				side / 2,
				1,
				1,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a,
				-side / 2,
				side / 2,
				-side / 2,
				0,
				1,
				_color.top.r,
				_color.top.g,
				_color.top.b,
				_color.top.a
			];
			vertexData = new Float32Array(v);
			_glVertexBuffer = gl.createBuffer();
			gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
			gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW);

			// Index for each cube face using the the vertex data above
			indexData = new Int32Array([
				 0,  3,    2, // Back
				 2,  1,           0,
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
			_glIndexBuffer = gl.createBuffer();
			gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _glIndexBuffer);
			gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);
		}
	}

	function initializeGl(gl:WebGLRenderContext):Void
	{
		if (!_glInitialized)
		{
			setupData(gl);
			_glInitialized = true;
		}
	}

	public function render(gl:WebGLRenderContext):Void
	{
		initializeGl(gl);
	}
}
