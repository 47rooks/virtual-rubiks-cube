package;

import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import lime.math.RGBA;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix3D;

class LightAGAL
{
	final LIGHT_SIZE = 20.0;
	final side = 1.0;

	var _x:Int;
	var _y:Int;
	var _z:Int;

	var _color:RGBA;

	// GL interface variables
	private var _context:Context3D;
	private var _program:Program3D;
	private var _programMatrixUniform:Int;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;

	public var _bitmapIndexBuffer:IndexBuffer3D;
	public var _bitmapVertexBuffer:VertexBuffer3D;

	var _modelMatrix:Matrix3D;

	public function new(context:Context3D, x:Int, y:Int, z:Int, color:RGBA)
	{
		_x = x;
		_y = y;
		_z = z;
		_context = context;
		_color = color;

		var vertexData = new Vector<Float>([ // X, Y, Z     R, G, B, A
			side / 2,
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a, // Back
			- side / 2,
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			-side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			-side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			-side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			-side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			-side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			-side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			-side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			-side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			-side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			-side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			-side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			-side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			side / 2,
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			side / 2,
			side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
			-side / 2,
			side / 2,
			-side / 2,
			_color.r,
			_color.g,
			_color.b,
			_color.a,
		]);

		_bitmapVertexBuffer = _context.createVertexBuffer(24, 7);
		_bitmapVertexBuffer.uploadFromVector(vertexData, 0, 24);

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
		_bitmapIndexBuffer = _context.createIndexBuffer(36);
		_bitmapIndexBuffer.uploadFromVector(indexData, 0, 36);

		_modelMatrix = new Matrix3D();
		_modelMatrix.append(createScaleMatrix(LIGHT_SIZE, LIGHT_SIZE, LIGHT_SIZE));
		_modelMatrix.append(createTranslationMatrix(_x, _y, _z));

		// Create GLSL program object
		createGLSLProgram();
	}

	function createGLSLProgram():Void
	{
		var vertexSource = "attribute vec4 aPosition;
            attribute vec4 aColor;
            varying vec4 vColor;
    
            uniform mat4 uMatrix;
            
            void main(void) {
                
                vColor = aColor / vec4(0xff);
                gl_Position = uMatrix * aPosition;
                
            }";

		var fragmentSource = #if !desktop "precision mediump float;" + #end

		"varying vec4 vColor;
            
            void main(void)
            {
                gl_FragColor = vColor;
            }";

		_program = _context.createProgram(GLSL);
		_program.uploadSources(vertexSource, fragmentSource);

		// Get references to GLSL attributes
		_programVertexAttribute = _program.getAttributeIndex("aPosition");
		_programColorAttribute = _program.getAttributeIndex("aColor");
		_programMatrixUniform = _program.getConstantIndex("uMatrix");

		trace('Light: aPosition=${_programVertexAttribute}, aColor=${_programColorAttribute}, uMatrix=${_programMatrixUniform}');
	}

	/**
	 * Render the light's current state.
	 * 
	 * @param projectionMatrix projection matrix to apply
	 */
	public function render(projectionMatrix:Matrix3D):Void
	{
		_context.setProgram(_program);

		// Create model/view/projection matrix from components
		var fullProjection = new Matrix3D();
		fullProjection.identity();
		fullProjection.append(_modelMatrix);

		fullProjection.append(projectionMatrix);

		_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _programMatrixUniform, fullProjection, false);
		_context.setVertexBufferAt(_programVertexAttribute, _bitmapVertexBuffer, 0, FLOAT_3);
		_context.setVertexBufferAt(_programColorAttribute, _bitmapVertexBuffer, 3, FLOAT_4);
		_context.drawTriangles(_bitmapIndexBuffer);
	}
}
