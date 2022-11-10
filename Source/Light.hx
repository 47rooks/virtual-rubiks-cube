package;

import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import MatrixUtils.matrix3DToFloat32Array;
import OpenGLUtils.glCreateProgram;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.RGBA;
import lime.utils.Float32Array;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix3D;

class Light
{
	final LIGHT_SIZE = 20.0;
	final side = 1.0;

	var _x:Float;
	var _y:Float;
	var _z:Float;

	private var _color:RGBA;

	// Model data
	var vertexData:Vector<Float>;
	var indexData:Vector<UInt>;

	// GL interface variables
	private var _glProgram:GLProgram;
	private var _glVertexBuffer:VertexBuffer3D;
	private var _glIndexBuffer:IndexBuffer3D;
	private var _programMatrixUniform:GLUniformLocation;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;

	var _modelMatrix:Matrix3D;

	public function new(position:Float32Array, color:RGBA, gl:WebGLRenderContext, context:Context3D)
	{
		_x = position[0];
		_y = position[1];
		_z = position[2];

		_color = color;
		initializeGl(gl, context);
	}

	function initializeGl(gl:WebGLRenderContext, context:Context3D):Void
	{
		vertexData = new Vector<Float>([ // X, Y, Z     R, G, B, A
			side / 2, // BTR   BACK
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // BTL
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // BBL
			- side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // BBR
			- side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // BTL   LEFT
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // FTL
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // FBL
			- side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // BBL
			- side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // FTL    FRONT
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // FTR
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // FBR
			- side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // FBL
			- side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // BTR     RIGHT
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // FTR
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // FBR
			- side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // BBR
			- side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // FBR    BOTTOM
			- side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // FBL
			- side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // BBL
			- side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // BBR
			- side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // BTR    TOP
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2, // FTR
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // FTL
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2, // BTL
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
		]);
		// _glVertexBuffer = gl.createBuffer();
		// gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
		// gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW);
		_glVertexBuffer = context.createVertexBuffer(24, 7);
		_glVertexBuffer.uploadFromVector(vertexData, 0, 168);

		// Index for each cube face using the the vertex data above
		// Cross check indexes with De Vries and make sure that we have the same points
		// ocurring in the same order.
		indexData = new Vector<UInt>([
			 0,  3,    2, // Back
			 2,  1,           0,
			 9, 11,  10, // Front
			11,  9,           8,
			 5,  4,    7, // Left
			 7,  6,           5,
			14, 15,  12, // Right
			12, 13,          14,
			18, 19, 16, // Bottom
			16, 17,          18,
			23, 20,    21, // Top
			22, 23,          21
		]);
		// _glIndexBuffer = gl.createBuffer();
		// gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _glIndexBuffer);
		// gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);
		_glIndexBuffer = context.createIndexBuffer(36);
		_glIndexBuffer.uploadFromVector(indexData, 0, 36);

		_modelMatrix = new Matrix3D();
		_modelMatrix.append(createScaleMatrix(LIGHT_SIZE, LIGHT_SIZE, LIGHT_SIZE));
		_modelMatrix.append(createTranslationMatrix(_x, _y, _z));

		// Create GLSL program object
		createGLSLProgram(gl);
	}

	function createGLSLProgram(gl:WebGLRenderContext):Void
	{
		var vertexSource = "attribute vec3 aPosition;
            attribute vec4 aColor;
            varying vec4 vColor;
    
            uniform mat4 uMatrix;
            
            void main(void) {
                
				vColor = aColor / vec4(0xff);
                gl_Position = uMatrix * vec4(aPosition, 1.0);  
            }";

		var fragmentSource = #if !desktop "precision mediump float;" + #end

		"varying vec4 vColor;
            
            void main(void)
            {
                gl_FragColor = vColor;
            }";

		// Delete old program - do I need this ?
		if (_glProgram != null)
		{
			if (_programVertexAttribute > -1)
				gl.disableVertexAttribArray(_programVertexAttribute);
			gl.disableVertexAttribArray(_programVertexAttribute);
			gl.deleteProgram(_glProgram);
		}

		_glProgram = glCreateProgram(gl, vertexSource, fragmentSource);
		if (_glProgram == null)
		{
			return;
		}

		// Get references to GLSL attributes
		_programVertexAttribute = gl.getAttribLocation(_glProgram, "aPosition");
		gl.enableVertexAttribArray(_programVertexAttribute);

		_programColorAttribute = gl.getAttribLocation(_glProgram, "aColor");
		gl.enableVertexAttribArray(_programColorAttribute);

		_programMatrixUniform = gl.getUniformLocation(_glProgram, "uMatrix");

		trace('Light: aPosition=${_programVertexAttribute}, aColor=${_programColorAttribute}, uMatrix=${_programMatrixUniform}');
	}

	/**
	 * Render the light's current state.
	 * 
	 * @param projectionMatrix projection matrix to apply
	 */
	public function render(gl:WebGLRenderContext, context:Context3D, projectionMatrix:Matrix3D):Void
	{
		if (_glProgram == null)
		{
			return;
		}

		// Create model/view/projection matrix from components
		var fullProjection = new Matrix3D();
		fullProjection.identity();
		fullProjection.append(_modelMatrix);

		fullProjection.append(projectionMatrix);

		gl.useProgram(_glProgram);

		gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(fullProjection));

		// gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
		// gl.vertexAttribPointer(_programVertexAttribute, 3, gl.FLOAT, false, 28, 0);
		// gl.vertexAttribPointer(_programColorAttribute, 4, gl.FLOAT, false, 28, 12);
		context.setVertexBufferAt(_programVertexAttribute, _glVertexBuffer, 0, FLOAT_3);
		context.setVertexBufferAt(_programColorAttribute, _glVertexBuffer, 3, FLOAT_4);

		// gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _glIndexBuffer);

		// gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, 0);
		context.drawTriangles(_glIndexBuffer);
		// gl.bindBuffer(gl.ARRAY_BUFFER, null);
		// gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
	}
}
