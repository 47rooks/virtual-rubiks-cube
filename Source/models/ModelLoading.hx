package models;

import gl.ModelLoadingProgram;
import lights.PointLight;
import lime.graphics.WebGLRenderContext;
import lime.utils.Float32Array;
import models.logl.GLTFModel;
import models.logl.Model;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import ui.UI;

class ModelLoading
{
	// Graphics Contexts
	var _gl:WebGLRenderContext;

	var _initialized:Bool = false;

	var _model:Model;
	var _modelLoadingProgram:ModelLoadingProgram;

	// Vectors and Matrices
	var _modelRotation:Matrix3D;
	var _yaw:Float;
	var _pitch:Float;

	final ROTATION_SENSITIVTY = 0.5;

	public function new(gl:WebGLRenderContext)
	{
		_gl = gl;
		_modelRotation = new Matrix3D();
	}

	private function initialize(gl:WebGLRenderContext):Void
	{
		if (_initialized)
		{
			return;
		}

		// Model loading
		_model = new GLTFModel(_gl, 'assets/gltf/backpack.gltf2', 'assets/gltf/backpack.bin');
		_modelLoadingProgram = new ModelLoadingProgram(_gl);

		_initialized = true;
	}

	public function update(elapsed:Float, ui:UI)
	{
		if (ui.sceneModelLoading)
		{
			initialize(_gl);
		}
	}

	public function render(gl:WebGLRenderContext, projectionMatrix:Matrix3D, cameraPosition:Float32Array, pointLights:Array<PointLight>,
			flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI):Void
	{
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);
		_modelLoadingProgram.use();
		_model.draw(_modelLoadingProgram, {
			vertexBufferData: null,
			indexBufferData: null,
			textures: null,
			modelMatrix: _modelRotation,
			projectionMatrix: projectionMatrix,
			cameraPosition: cameraPosition,
			lightColor: null,
			lightPosition: null,
			directionalLight: lightDirection,
			pointLights: pointLights,
			flashlightPos: flashlightPos,
			flashlightDir: flashlightDir,
			ui: ui
		});
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
