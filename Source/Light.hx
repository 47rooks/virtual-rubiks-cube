package;

import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.RGBA;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import openfl.geom.Matrix3D;

class Light
{
	final LIGHT_SIZE = 20.0;
	final side = 1.0;

	var _x:Int;
	var _y:Int;
	var _z:Int;

	private var _color:RGBA;

	// Model data
	var vertexData:Float32Array;
	var indexData:Int32Array;

	// GL interface variables
	private var _glProgram:GLProgram;
	private var _glVertexBuffer:GLBuffer;
	private var _glIndexBuffer:GLBuffer;
	private var _programMatrixUniform:GLUniformLocation;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	private var _glInitialized = false;

	var _modelMatrix:Matrix3D;

	public function new(x:Int, y:Int, z:Int, color:RGBA)
	{
		_x = x;
		_y = y;
		_z = z;
		_color = color;
	}

	function setupData(gl:WebGLRenderContext):Void
	{
		vertexData = new Float32Array([ // X, Y, Z     R, G, B, A
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
		_glVertexBuffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW);

		// Index for each cube face using the the vertex data above
		// Cross check indexes with De Vries and make sure that we have the same points
		// ocurring in the same order.
		indexData = new Int32Array([
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
		_glIndexBuffer = gl.createBuffer();
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _glIndexBuffer);
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);

		_modelMatrix = new Matrix3D();
		_modelMatrix.append(createScaleMatrix(LIGHT_SIZE, LIGHT_SIZE, LIGHT_SIZE));
		_modelMatrix.append(createTranslationMatrix(_x, _y, _z));

		// Create GLSL program object
		createGLSLProgram(gl);
	}

	function glCreateShader(gl:WebGLRenderContext, source:String, type:Int):GLShader
	{
		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);

		if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0)
		{
			trace(gl.getShaderInfoLog(shader));
			return null;
		}

		return shader;
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

		var vs = glCreateShader(gl, vertexSource, gl.VERTEX_SHADER);
		var fs = glCreateShader(gl, fragmentSource, gl.FRAGMENT_SHADER);

		if (vs == null || fs == null)
		{
			return;
		}

		var program = gl.createProgram();
		gl.attachShader(program, vs);
		gl.attachShader(program, fs);

		gl.deleteShader(vs);
		gl.deleteShader(fs);

		gl.linkProgram(program);

		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			trace(gl.getProgramInfoLog(program));
			trace("VALIDATE_STATUS: " + gl.getProgramParameter(program, gl.VALIDATE_STATUS));
			trace("ERROR: " + gl.getError());
			return;
		}

		// Delete old program - do I need this ?
		if (_glProgram != null)
		{
			if (_programVertexAttribute > -1)
				gl.disableVertexAttribArray(_programVertexAttribute);
			gl.disableVertexAttribArray(_programVertexAttribute);
			gl.deleteProgram(_glProgram);
		}

		_glProgram = program;

		// Get references to GLSL attributes
		_programVertexAttribute = gl.getAttribLocation(_glProgram, "aPosition");
		gl.enableVertexAttribArray(_programVertexAttribute);

		_programColorAttribute = gl.getAttribLocation(_glProgram, "aColor");
		gl.enableVertexAttribArray(_programColorAttribute);

		_programMatrixUniform = gl.getUniformLocation(_glProgram, "uMatrix");

		trace('Light: aPosition=${_programVertexAttribute}, aColor=${_programColorAttribute}, uMatrix=${_programMatrixUniform}');
	}

	function initializeGl(gl:WebGLRenderContext):Void
	{
		if (!_glInitialized)
		{
			setupData(gl);
			_glInitialized = true;
		}
	}

	/**
	 * Render the light's current state.
	 * 
	 * @param projectionMatrix projection matrix to apply
	 */
	public function render(gl:WebGLRenderContext, projectionMatrix:Matrix3D):Void
	{
		initializeGl(gl);

		if (_glProgram == null)
		{
			return;
		}

		// Create model/view/projection matrix from components
		var fullProjection = new Matrix3D();
		fullProjection.identity();
		fullProjection.append(_modelMatrix);

		fullProjection.append(projectionMatrix);

		var fPArray = new Array<Float>();
		for (v in fullProjection.rawData)
		{
			fPArray.push(v);
		}
		var fP = new Float32Array(fPArray);

		gl.useProgram(_glProgram);

		gl.uniformMatrix4fv(_programMatrixUniform, false, fP);

		gl.bindBuffer(gl.ARRAY_BUFFER, _glVertexBuffer);
		gl.vertexAttribPointer(_programVertexAttribute, 3, gl.FLOAT, false, 28, 0);
		gl.vertexAttribPointer(_programColorAttribute, 4, gl.FLOAT, false, 28, 12);

		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _glIndexBuffer);
		gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, 0);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
	}
}
