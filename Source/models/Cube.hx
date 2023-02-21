package models;

import Color.WHITE;
import lime.graphics.WebGL2RenderContext;
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
	public var vbo:GLBuffer;
	public var ebo:GLBuffer;
	public var numIndexes:Int;

	// GL interface variables
	private var _programMatrixUniform:GLUniformLocation;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;

	private var _color:ColorSpec;

	/**
	 * Constructor
	 * @param gl The WebGL render context
	 * @param color a ColorSpec specifying colors for each face. If null, all faces will be all white.
	 */
	public function new(gl:WebGL2RenderContext, color:ColorSpec)
	{
		if (color != null)
		{
			_color = color;
		}
		else
		{
			_color = {
				front: WHITE,
				back: WHITE,
				top: WHITE,
				bottom: WHITE,
				left: WHITE,
				right: WHITE
			};
		}
		initializeBuffers(gl);
	}

	function initializeBuffers(gl:WebGL2RenderContext):Void
	{
		final side = 1.0;

		var v = [ // X, Y, Z                        U, V   R, G, B, A,    Nx, Ny, Nz
			side / 2.0,
			side / 2,
			-side / 2,
			0,
			0,
			_color.back.r,
			_color.back.g,
			_color.back.b,
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
			_color.back.b,
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
			_color.back.b,
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
			_color.back.b,
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
		var vertexData = new Float32Array(v);
		vbo = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
		gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);

		// Index for each cube face using the the vertex data above

		var indexData = new Int32Array([
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
		ebo = gl.createBuffer();
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
		numIndexes = indexData.length;
	}
}
