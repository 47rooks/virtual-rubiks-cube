package models;

import gl.ModelLoadingProgram;
import lights.PointLight;
import lime.graphics.WebGLRenderContext;
import lime.math.RGBA;
import lime.utils.Float32Array;
import models.logl.Model;
import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import ui.UI;

class ModelLoading
{
	// Graphics Contexts
	var _gl:WebGLRenderContext;
	var _context:Context3D;

	var _initialized:Bool = false;

	var _model:Model;
	var _modelLoadingProgram:ModelLoadingProgram;

	// Vectors and Matrices
	var _modelRotation:Matrix3D;
	var _yaw:Float;
	var _pitch:Float;

	final ROTATION_SENSITIVTY = 0.5;

	public function new(gl:WebGLRenderContext, context:Context3D)
	{
		_gl = gl;
		_context = context;
		_modelRotation = new Matrix3D();
	}

	private function initialize(gl:WebGLRenderContext, context:Context3D):Void
	{
		if (_initialized)
		{
			return;
		}

		// Model loading
		_model = new Model(_gl, _context, 'assets/gltf/backpack.gltf2', 'assets/gltf/backpack.bin');
		_modelLoadingProgram = new ModelLoadingProgram(_gl, _context);

		_initialized = true;
	}

	public function update(elapsed:Float, ui:UI)
	{
		if (ui.sceneModelLoading)
		{
			initialize(_gl, _context);
		}
	}

	public function render(gl:WebGLRenderContext, context:Context3D, projectionMatrix:Matrix3D, cameraPosition:Float32Array, pointLights:Array<PointLight>,
			flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI):Void
	{
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);
		_modelLoadingProgram.use();
		_model.draw(_modelLoadingProgram, _modelRotation, projectionMatrix, lightDirection, cameraPosition, pointLights, flashlightPos, flashlightDir, ui);
	}

	/**
	 * Rotate the model in space.
	 * @param xOffset x axis offset from current value
	 * @param yOffset y axis offset from current value
	 */
	public function rotate(xOffset:Float, yOffset:Float):Void
	{
		var deltaX = xOffset * ROTATION_SENSITIVTY;
		var deltaY = yOffset * ROTATION_SENSITIVTY;

		_yaw += deltaX;
		_pitch += deltaY;

		if (_pitch > 89)
		{
			_pitch = 89;
		}
		if (_pitch < -89)
		{
			_pitch = -89;
		}

		var rotation = new Matrix3D();
		rotation.appendRotation(_yaw, new Vector3D(0, 1, 0));
		rotation.appendRotation(_pitch, new Vector3D(1, 0, 0));
		_modelRotation = rotation;
	}
}
