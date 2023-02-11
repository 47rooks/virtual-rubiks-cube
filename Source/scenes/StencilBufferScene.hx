package scenes;

import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import MatrixUtils.vector3DToFloat32Array;
import gl.ModelLoadingProgram;
import gl.OutliningProgram;
import lights.Flashlight;
import lights.PointLight;
import lime.utils.Float32Array;
import models.logl.CubeModel;
import models.logl.Model;
import models.logl.PlaneModel;
import openfl.events.Event;
import openfl.geom.Vector3D;
import ui.UI;

/*
 * The StencilBufferScene demonstrates the use of the stencil buffer to 
 * render an outline around some objects while others remain un-outlined.
 */
class StencilBufferScene extends BaseScene
{
	var _pointLights:Array<PointLight>;

	public static final NUM_POINT_LIGHTS = 4;

	// Flashlight
	var _flashlight:Flashlight;

	var _models:Array<Model>;
	var _modelLoadingProgram:ModelLoadingProgram;
	var _outliningProgram:OutliningProgram;

	public function new(ui:UI):Void
	{
		super(ui);
		_models = new Array<Model>();
	}

	function addedToStage(e:Event)
	{
		_camera = new Camera(new Vector3D(0, 0, 200), new Vector3D(0, 1, 0));

		// Compute projection matrix
		// Uncomment the createOrthoProjection() line and comment the next for an orthographic view.
		// Note that mouse wheel zoom will switch back to perspective projection as it
		//      recreates the projection matrix and only supports doing so for the
		//      perspective projection. See mouseOnWheel().
		// projectionTransform = createOrthoProjection(-300.0, 300.0, 300.0, -300.0, 100, 1000);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		_models.push(new CubeModel(_gl));
		_models.push(new CubeModel(_gl, 0.5, 0.25, 0.5));
		_models.push(new CubeModel(_gl, -0.75, 0.25, 0.5));
		_models.push(new PlaneModel(_gl));

		_modelLoadingProgram = new ModelLoadingProgram(_gl);
		_outliningProgram = new OutliningProgram(_gl);

		// There are four point lights with positions scaled by 64.0 (which is the scale of the cube size)
		// compared to DeVries original. Strictly this should be programmatically scaled by RubiksCube.SIDE.
		// Previously used single point light location was [200.0, 200.0, 200.0]
		_pointLights = new Array<PointLight>();
		final pointLightPositions = [
			[80.0, 100.0, 128.0],
			[147.2, -211.2, -256.0],
			[-256.0, 128.0, -768.0],
			[0.0, 0.0, -192.0]
		];
		for (i in 0...NUM_POINT_LIGHTS)
		{
			_pointLights[i] = new PointLight(new Float32Array(pointLightPositions[i]), Color.WHITE, _gl);
		}
	}

	function close() {}

	function render()
	{
		var cameraPos = vector3DToFloat32Array(_camera.cameraPos);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);

		_modelLoadingProgram.use();
		// Draw floor before enabling the stencil buffer. If the floor were to write to the stencil
		// buffer the outlining would not appear when looking down on the scene from above.
		// Offset floor a little downward to prevent z-fighting between the bottom of the cubes and the floor.
		var translation = createTranslationMatrix(0.0, -0.001, 0.0);
		translation.append(_sceneRotation);

		_models[3].draw(_modelLoadingProgram, {
			vbo: null,
			vertexBufferData: null,
			ibo: null,
			indexBufferData: null,
			textures: null,
			modelMatrix: translation,
			projectionMatrix: lookAtMat,
			cameraPosition: cameraPos,
			lightColor: null,
			lightPosition: null,
			directionalLight: lightDirection,
			pointLights: _pointLights,
			flashlightPos: cameraPos,
			flashlightDir: vector3DToFloat32Array(_camera.cameraFront),
			ui: _ui
		});

		// Set stencil buffer to update
		_gl.enable(_gl.STENCIL_TEST);
		_gl.stencilOp(_gl.KEEP, _gl.KEEP, _gl.REPLACE);
		_gl.stencilFunc(_gl.ALWAYS, 1, 0xFF);
		_gl.stencilMask(0xFF);

		// Draw initial correct model size
		for (m in _models.slice(0, 3))
		{
			m.draw(_modelLoadingProgram, {
				vbo: null,
				vertexBufferData: null,
				ibo: null,
				indexBufferData: null,
				textures: null,
				modelMatrix: _sceneRotation,
				projectionMatrix: lookAtMat,
				cameraPosition: cameraPos,
				lightColor: null,
				lightPosition: null,
				directionalLight: lightDirection,
				pointLights: _pointLights,
				flashlightPos: cameraPos,
				flashlightDir: vector3DToFloat32Array(_camera.cameraFront),
				ui: _ui
			});
		}

		// Disable stencil buffer writes, depth buffer and set comparison operation
		_gl.stencilFunc(_gl.NOTEQUAL, 1, 0xFF);
		_gl.stencilMask(0x00); // disable stencil buffer writes
		_gl.disable(_gl.DEPTH_TEST);

		// Scale models of the two cubes a little and redraw
		// use a simple program - doesn't need textures, just draws one color
		_outliningProgram.use();
		var scaleMatrix = createScaleMatrix(1.1, 1.1, 1.1);
		scaleMatrix.append(_sceneRotation);
		for (m in _models.slice(0, 2))
		{
			m.draw(_outliningProgram, {
				vbo: null,
				vertexBufferData: null,
				ibo: null,
				indexBufferData: null,
				textures: null,
				modelMatrix: scaleMatrix,
				projectionMatrix: lookAtMat,
				cameraPosition: cameraPos,
				lightColor: null,
				lightPosition: null,
				directionalLight: lightDirection,
				pointLights: _pointLights,
				flashlightPos: cameraPos,
				flashlightDir: vector3DToFloat32Array(_camera.cameraFront),
				ui: _ui
			});
		}

		// Re-enable depth buffer
		_gl.enable(_gl.DEPTH_TEST);

		// Disable the stencil test. Reset the stencil parameters - this is very important because stencil
		// buffer remnants will cause strange side-affects.
		_gl.stencilMask(0xFF);
		_gl.stencilFunc(_gl.ALWAYS, 1, 0xFF);
		_gl.disable(_gl.STENCIL_TEST);

		// Rendering the point light objects
		// FIXME might reposition the lights - well point light 1 - it's in the way
		for (i in 0...NUM_POINT_LIGHTS)
		{
			if (_ui.pointLight(i).uiPointLightEnabled.selected)
			{
				_pointLights[i].render(_gl, lookAtMat, _ui);
			}
		}
	}
}
