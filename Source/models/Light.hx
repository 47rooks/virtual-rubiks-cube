package models;

import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import gl.LightProgram;
import lime.graphics.WebGLRenderContext;
import lime.math.RGBA;
import lime.utils.Float32Array;
import openfl.geom.Matrix3D;
import ui.UI;

/**
 * A simple light - a single color cube.
 */
class Light
{
	final LIGHT_SIZE = 20.0;
	final side = 1.0;

	var _x:Float;
	var _y:Float;
	var _z:Float;

	private var _color:RGBA;

	// Model data
	var vertexData:Float32Array;
	var indexData:Float32Array;

	var _modelMatrix:Matrix3D;

	final _program:LightProgram;

	/**
	 * Constructor
	 * @param position The world position for the light
	 * @param color The color of the light
	 * @param gl The WebGL render context
	 */
	public function new(position:Float32Array, color:RGBA, gl:WebGLRenderContext)
	{
		_x = position[0];
		_y = position[1];
		_z = position[2];

		_color = color;
		initializeBuffers(gl);

		_program = new LightProgram(gl);
	}

	function initializeBuffers(gl:WebGLRenderContext):Void
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

		// Index for each cube face using the the vertex data above
		// Cross check indexes with De Vries and make sure that we have the same points
		// ocurring in the same order.
		indexData = new Float32Array([
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

		_modelMatrix = new Matrix3D();
		_modelMatrix.append(createScaleMatrix(LIGHT_SIZE, LIGHT_SIZE, LIGHT_SIZE));
		_modelMatrix.append(createTranslationMatrix(_x, _y, _z));
	}

	/**
	 * Render the light's current state.
	 * 
	 * @param gl The WebGL render context
	 * @param projectionMatrix projection matrix to apply
	 * @param ui the UI instance
	 */
	public function render(gl:WebGLRenderContext, projectionMatrix:Matrix3D, ui:UI):Void
	{
		// Create model/view/projection matrix from components
		var fullProjection = new Matrix3D();
		fullProjection.identity();
		fullProjection.append(_modelMatrix);

		fullProjection.append(projectionMatrix);

		_program.use();
		_program.render({
			vbo: null,
			vertexBufferData: vertexData,
			ibo: null,
			numIndexes: 0,
			indexBufferData: indexData,
			textures: null,
			modelMatrix: _modelMatrix,
			projectionMatrix: fullProjection,
			cameraPosition: null,
			lightColor: null,
			lightPosition: null,
			directionalLight: null,
			pointLights: null,
			flashlightPos: null,
			flashlightDir: null,
			ui: ui
		});
	}
}
