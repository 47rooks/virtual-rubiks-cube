package models;

import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import gl.LightCastersProgram;
import lights.PointLight;
import lime.graphics.WebGLRenderContext;
import lime.math.RGBA;
import lime.utils.Float32Array;
import openfl.Assets;
import openfl.display3D.Context3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import ui.UI;

/**
 * A cloud of cubes in space. The number of cubes may be varied up to a maximum (currently 10)
 * dynamically on each render. Cube locations in space are fixed.
 */
class CubeCloud
{
	/* Individual cube positions */
	var _cubesPositions:Array<Float32Array>;
	var _cubeModel:Cube;
	var _cubeProgram:LightCastersProgram;

	// Lighting map textures
	private var _diffuseLightMapTexture:RectangleTexture;

	private var _specularLightMapTexture:RectangleTexture;

	public function new(gl:WebGLRenderContext, context:Context3D)
	{
		initializeCubePositions(gl, context);
	}

	private function initializeCubePositions(gl:WebGLRenderContext, context:Context3D):Void
	{
		_cubesPositions = new Array<Float32Array>();
		_cubesPositions[0] = new Float32Array([0.0, 0.0, 0.0]);
		_cubesPositions[1] = new Float32Array([2.0, 5.0, -15.0]); // FIXME renders beyond frustum
		_cubesPositions[2] = new Float32Array([-1.5, -2.2, -2.5]);
		_cubesPositions[3] = new Float32Array([-3.8, -2.0, -2.5]);
		_cubesPositions[4] = new Float32Array([2.4, -0.4, -3.5]);
		_cubesPositions[5] = new Float32Array([-1.7, 3.0, -7.5]);
		_cubesPositions[6] = new Float32Array([1.3, -2.0, -2.5]);
		_cubesPositions[7] = new Float32Array([1.5, 2.0, -2.5]);
		_cubesPositions[8] = new Float32Array([1.5, 0.2, -1.5]);
		_cubesPositions[9] = new Float32Array([-1.3, 1.0, -1.5]);

		_cubeModel = new Cube(null, context);
		_cubeProgram = new LightCastersProgram(gl, context);

		// Load texture - FIXME note this is duplicate code - same texture is loaded in
		var diffuseLightMapImageData = Assets.getBitmapData("assets/openflMetalDiffuse.png");
		_diffuseLightMapTexture = context.createRectangleTexture(diffuseLightMapImageData.width, diffuseLightMapImageData.height, BGRA, false);
		_diffuseLightMapTexture.uploadFromBitmapData(diffuseLightMapImageData);

		var specularLightMapImageData = Assets.getBitmapData("assets/openflMetalSpecular.png");
		_specularLightMapTexture = context.createRectangleTexture(specularLightMapImageData.width, specularLightMapImageData.height, BGRA, false);
		_specularLightMapTexture.uploadFromBitmapData(specularLightMapImageData);
	}

	public function update(elapsed:Float) {}

	/* FIXME lightPosition is not used - remove */
	public function render(gl:WebGLRenderContext, context:Context3D, projectionMatrix:Matrix3D, lightColor:RGBA, lightPosition:Float32Array,
			cameraPosition:Float32Array, pointLights:Array<PointLight>, flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI):Void
	{
		var lightColorArr = new Float32Array([lightColor.r, lightColor.g, lightColor.b]);
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);
		var scale = 64;
		_cubeProgram.use();

		for (i in 0...ui.numOfCubes)
		{
			var model = createScaleMatrix(scale, scale, scale);
			// FIXME mult. by 64 is a hack and kicks one cube beyond the frustum.
			model.append(createTranslationMatrix(_cubesPositions[i][0] * scale, _cubesPositions[i][1] * scale, _cubesPositions[i][2] * scale));
			var angle = 20.0 * i;
			model.appendRotation(angle, new Vector3D(1.0, 0.3, 0.5));

			var fullProjection = model.clone();
			fullProjection.append(projectionMatrix);

			_cubeProgram.render({
				vbo: _cubeModel._glVertexBuffer,
				ibo: _cubeModel._glIndexBuffer,
				textures: [_diffuseLightMapTexture, _specularLightMapTexture],
				modelMatrix: model,
				projectionMatrix: fullProjection,
				cameraPosition: cameraPosition,
				lightColor: lightColorArr,
				lightPosition: null,
				directionalLight: lightDirection,
				pointLights: pointLights,
				flashlightPos: flashlightPos,
				flashlightDir: flashlightDir,
				ui: ui
			});
		}
	}
}
