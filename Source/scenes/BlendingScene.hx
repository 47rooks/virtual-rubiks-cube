package scenes;

import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createRotationMatrix;
import MatrixUtils.vector3DToFloat32Array;
import gl.BlendingProgram;
import gl.ModelLoadingProgram;
import lights.Flashlight;
import lights.PointLight;
import lime.utils.Float32Array;
import models.logl.CubeModel;
import models.logl.Model;
import models.logl.PlaneModel;
import models.logl.QuadModel;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import ui.UI;

/**
 * This scene demonstrates blending in OpenGL.
 */
class BlendingScene extends BaseScene
{
	var _pointLights:Array<PointLight>;

	public static final NUM_POINT_LIGHTS = 4;

	// Flashlight
	var _flashlight:Flashlight;

	var _models:Array<Model>;
	var _grassModels:Array<Model>;
	var _windowModels:Array<Model>;
	var _modelLoadingProgram:ModelLoadingProgram;
	var _blendingProgram:BlendingProgram;
	var _locs:Array<Array<Float>>;

	/**
	 * Constructor
	 * @param ui the UI instance
	 */
	public function new(ui:UI)
	{
		super(ui);
		_models = new Array<Model>();
		_grassModels = new Array<Model>();
		_windowModels = new Array<Model>();
		_controlTarget = MODEL;

        // @formatter:off
		/**
		 * This is a quick hack to make the positions accessible. The position should be a model
         * attribute.
		 */
		_locs = [[-1.5, 0.0, -0.48],
                 [ 1.5, 0.0,  0.51],
                 [ 0.0, 0.0,  0.7],
                 [-0.3, 0.0, -2.3],
                 [ 0.5, 0.0, -0.6]
                ];
        // @formatter:on
	}

	function update(elapsed:Float)
	{
		_deltaTime = elapsed / 1000.0;

		if (_ui.mouseTargetsCube)
		{
			_controlTarget = MODEL;
		}
		else
		{
			_controlTarget = CAMERA;
		}
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

		// Basic scene floor and blocks
		_models.push(new CubeModel(_gl, _context, 1.5, 0.0, 0.0));
		_models.push(new CubeModel(_gl, _context, -1.5, 0.0, -1.0));
		_models.push(new PlaneModel(_gl, _context));

		// Vegetation quads
		var rotMatrix = createRotationMatrix(-90, Vector3D.X_AXIS);
		for (loc in _locs)
		{
			var m = rotMatrix.clone();
			m.appendTranslation(loc[0], loc[1], loc[2]);
			_grassModels.push(new QuadModel(_gl, _context, 'assets/grass.png', m));
			_windowModels.push(new QuadModel(_gl, _context, 'assets/window.png', m));
		}

		_blendingProgram = new BlendingProgram(_gl, _context);
		_modelLoadingProgram = new ModelLoadingProgram(_gl, _context);

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
			_pointLights[i] = new PointLight(new Float32Array(pointLightPositions[i]), Color.WHITE, _gl, _context);
		}
	}

	function close() {}

	function render()
	{
		if (_ui.uiDiscardingEnabled.selected)
		{
			if (!_ui.blendingEnabled)
			{
				/* Context3D enables blending by default. To see the effect of not enabling blending
				 * the user can disable it. If they do turn off blending here and re-enable it once
				 * this render has finished
				 */
				_gl.disable(_gl.BLEND);
			}
			renderInternal(_grassModels);

			if (!_ui.blendingEnabled && _ui.uiDiscardingEnabled.selected)
			{
				_gl.enable(_gl.BLEND);
			}
		}
		else if (_ui.uiSemiTransparentEnabled.selected)
		{
			var windows:Array<Model>;
			if (_ui.uiSortWindows.selected)
			{
				windows = new Array<Model>();
				var distances = new Array<{i:Int, d:Float}>();
				for (i => pos in _locs)
				{
					var pVec = new Vector3D(pos[0], pos[1], pos[2]);
					var rVec = _sceneRotation.transformVector(pVec);
					var d = Vector3D.distance(_camera.cameraPos, rVec);
					distances.push({i: i, d: d});
				}
				distances.sort(function(a, b)
				{
					if (a.d < b.d)
						return 1;
					else if (a.d > b.d)
						return -1;
					else
						return 0;
				});
				for (d in distances)
				{
					windows.push(_windowModels[d.i]);
				}
			}
			else
			{
				windows = _windowModels;
			}

			/* Set the blendFunc per the UI selections from the user.
			 * Default to the simple src_alpha/1-src_alpha.
			 */
			var srcBlendFunc = convertNameToBlendFunc(_ui.sourceBlendFunc);
			var dstBlendFunc = convertNameToBlendFunc(_ui.destBlendFunc);
			_gl.blendFunc(srcBlendFunc != null ? srcBlendFunc : _gl.SRC_ALPHA, dstBlendFunc != null ? dstBlendFunc : _gl.ONE_MINUS_SRC_ALPHA);

			renderInternal(windows);

			/* Restore default blendfunc so the Context3D doesn't get confused
			 */

			_context.setBlendFactors(SOURCE_ALPHA, ONE_MINUS_SOURCE_ALPHA);
		}
	}

	function renderInternal(models2D:Array<Model>)
	{
		// _context.setBlendFactors(SOURCE_ALPHA, ONE_MINUS_SOURCE_ALPHA);

		var cameraPos = vector3DToFloat32Array(_camera.cameraPos);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);
		var lightDirection = new Float32Array([-0.2, -1.0, -0.3]);

		_modelLoadingProgram.use();
		_context.setSamplerStateAt(0, REPEAT, NEAREST, MIPNONE);

		// Draw initial correct model size
		for (m in _models)
		{
			m.draw(_modelLoadingProgram, {
				vbo: null,
				ibo: null,
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

		// Render the grass
		_blendingProgram.use();
		for (m in models2D)
		{
			m.draw(_blendingProgram, {
				vbo: null,
				ibo: null,
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
	}

	/**
	 * Convert the name to blend function constant.
	 * @param name blend function name
	 * @return Null<Int>
	 */
	function convertNameToBlendFunc(name:String):Null<Int>
	{
		switch (name)
		{
			case "GL_ZERO":
				return _gl.ZERO;
			case "GL_ONE":
				return _gl.ONE;
			case "GL_SRC_COLOR":
				return _gl.SRC_COLOR;
			case "GL_ONE_MINUS_SRC_COLOR":
				return _gl.ONE_MINUS_SRC_COLOR;
			case "GL_DST_COLOR":
				return _gl.DST_COLOR;
			case "GL_ONE_MINUS_DST_COLOR":
				return _gl.ONE_MINUS_DST_COLOR;
			case "GL_SRC_ALPHA":
				return _gl.SRC_ALPHA;
			case "GL_ONE_MINUS_SRC_ALPHA":
				return _gl.ONE_MINUS_SRC_ALPHA;
			case "GL_DST_ALPHA":
				return _gl.DST_ALPHA;
			case "GL_ONE_MINUS_DST_ALPHA":
				return _gl.ONE_MINUS_DST_ALPHA;
			case "GL_CONSTANT_COLOR":
				return _gl.CONSTANT_COLOR;
			case "GL_ONE_MINUS_CONSTANT_COLOR":
				return _gl.ONE_MINUS_CONSTANT_COLOR;
			case "GL_CONSTANT_ALPHA":
				return _gl.CONSTANT_ALPHA;
			case "GL_ONE_MINUS_CONSTANT_ALPHA":
				return _gl.ONE_MINUS_CONSTANT_ALPHA;
			case "GL_SRC_ALPHA_SATURATE":
				return _gl.SRC_ALPHA_SATURATE;
			default:
				return null;
		}
	}
}
