package scenes;

import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createTranslationMatrix;
import MatrixUtils.vector3DToFloat32Array;
import gl.ModelLoadingProgram;
import lights.PointLight;
import lime.utils.Float32Array;
import models.logl.CubeModel;
import models.logl.Model;
import openfl.events.Event;
import openfl.geom.Vector3D;
import ui.UI;

/**
 * Culling scene provides a simple single cube model with face culling options. You can alter the front face winding order and the faces that are culled.
 */
class CullingScene extends BaseScene
{
	var _pointLights:Array<PointLight>;

	public static final NUM_POINT_LIGHTS = 4;

	var _models:Array<Model>;
	var _cullingProgram:ModelLoadingProgram;

	public function new(ui:UI)
	{
		super(ui);
		_models = new Array<Model>();
	}

	function addedToStage(e:Event)
	{
		_camera = new Camera(new Vector3D(0, 0, 200), new Vector3D(0, 1, 0));

		// Compute projection matrix
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		_models.push(new CubeModel(_gl));

		_cullingProgram = new ModelLoadingProgram(_gl);

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

		_cullingProgram.use();

		// Draw floor before enabling the stencil buffer. If the floor were to write to the stencil
		// buffer the outlining would not appear when looking down on the scene from above.
		// Offset floor a little downward to prevent z-fighting between the bottom of the cubes and the floor.
		var translation = createTranslationMatrix(0.0, -0.001, 0.0);
		translation.append(_sceneRotation);

		// Enable culling
		if (_ui.cullingEnabled)
		{
			if (_ui.ccw)
			{
				_gl.frontFace(_gl.CCW);
			}
			else if (_ui.cw)
			{
				_gl.frontFace(_gl.CW);
			}
			if (_ui.cullBackFace)
			{
				_gl.cullFace(_gl.BACK);
			}
			else if (_ui.cullFrontFace)
			{
				_gl.cullFace(_gl.FRONT);
			}
			else
			{
				_gl.cullFace(_gl.FRONT_AND_BACK);
			}
			_gl.enable(_gl.CULL_FACE);
		}

		for (m in _models)
		{
			m.draw(_cullingProgram, {
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
		}

		_gl.disable(_gl.CULL_FACE);
	}
}
