package scenes;

import Color.WHITE;
import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.vector3DToFloat32Array;
import lights.Flashlight;
import lights.PointLight;
import lime.math.RGBA;
import lime.utils.Float32Array;
import models.CubeCloud;
import models.Light;
import models.RubiksCube;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.geom.Vector3D;
import openfl.ui.Keyboard;
import scenes.BaseScene;
import ui.UI;

enum SceneSubType
{
	RUBIKS;
	RUBIKS_WITH_LIGHT;
	CUBE_CLOUD;
}

/**
 * BasicsScene is the scene used for exercises in the first two parts of Learn OpenGL.
 * It contains all the world objects and drives the rendering of all of them. It is created
 * in the normal way doing most of the work in the ADDED_TO_STAGE event handler.
 * 
 * It does contain some experimental gamepad support but it is by no means complete or fully worked
 * out.
 */
class BasicsScene extends BaseScene
{
	// Objects
	/* Rubik's cube */
	var _rubiksCube:RubiksCube;
	var operations:Array<Operation>;
	var operNum:Int;

	// Cube Cloud
	var _cubeCloud:CubeCloud;

	// Lights
	// Simple 3-component light
	var _light:Light;
	final LIGHT_COLOR = WHITE;
	final _lightPosition:Float32Array;

	// Point Light
	var _pointLights:Array<PointLight>;

	public static final NUM_POINT_LIGHTS = 4;

	// Flashlight
	var _flashlight:Flashlight;

	public function new(ui:UI)
	{
		super(ui);

		// Initialize key fields
		_deltaTime = 0;

		_camera = new Camera(new Vector3D(0, 0, 500), new Vector3D(0, 1, 0));

		_lightPosition = new Float32Array([200.0, 200.0, 200.0]);
	}

	function addedToStage(e:Event):Void
	{
		_gl = stage.window.context.webgl;

		// Compute projection matrix
		// Uncomment the createOrthoProjection() line and comment the next for an orthographic view.
		// Note that mouse wheel zoom will switch back to perspective projection as it
		//      recreates the projection matrix and only supports doing so for the
		//      perspective projection. See mouseOnWheel().
		// projectionTransform = createOrthoProjection(-300.0, 300.0, 300.0, -300.0, 100, 1000);
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		// GL  comment for now
		_rubiksCube = new RubiksCube(Math.ceil(stage.stageWidth / 2), Math.ceil(stage.stageHeight / 2), Math.ceil(256 / 2), this, _gl);

		// Add lights
		_light = new Light(_lightPosition, LIGHT_COLOR, _gl);

		_cubeCloud = new CubeCloud(_gl);

		// There are four point lights with positions scaled by 64.0 (which is the scale of the cube size)
		// compared to DeVries original. Strictly this should be programmatically scaled by RubiksCube.SIDE.
		// Previously used single point light location was [200.0, 200.0, 200.0]
		_pointLights = new Array<PointLight>();
		final pointLightPositions = [
			[44.8, 12.8, 128.0],
			[147.2, -211.2, -256.0],
			[-256.0, 128.0, -768.0],
			[0.0, 0.0, -192.0]
		];

		for (i in 0...NUM_POINT_LIGHTS)
		{
			_pointLights[i] = new PointLight(new Float32Array(pointLightPositions[i]), LIGHT_COLOR, _gl);
		}

		_flashlight = new Flashlight(vector3DToFloat32Array(_camera.cameraPos), vector3DToFloat32Array(_camera.cameraFront), 30, _gl);

		// Add completion event listener
		addEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, nextOperation);

		// // Add key listener to start example rotations
		// stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		// Setup the operations
		operations = new Array<Operation>();
		operNum = 0;
	}

	function close():Void
	{
		removeEventListener(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, nextOperation);
	}

	/**
	 * Set the scene objects according to the selected mode.
	 * For the moment this is a simple hack to return an enum.
	 * Ultimately we need an interface def (update/render) for
	 * all scene objects.
	 * @param ui UI parameters
	 */
	private function setScene(ui:UI):SceneSubType
	{
		if (ui.sceneCubeCloud)
		{
			return SceneSubType.CUBE_CLOUD;
		}
		else if (ui.sceneRubiksWithLight)
		{
			return SceneSubType.RUBIKS_WITH_LIGHT;
		}

		return SceneSubType.RUBIKS;
	}

	/**
	 * Update the current state.
	 * 
	 * @param elapsed elapsed time since last call.
	 */
	override function update(elapsed:Float):Void
	{
		// Poll inputs that require it
		for (gp in _gamepads)
		{
			pollGamepad(gp);
		}

		// FIXME Add a configure scene method that sets up the right collection of object
		// based on the selected scene.
		switch (setScene(_ui))
		{
			case RUBIKS:
				{
					_rubiksCube.update(elapsed);
				}
			case RUBIKS_WITH_LIGHT:
				{
					_rubiksCube.update(elapsed);
				}
			case CUBE_CLOUD:
				{
					_cubeCloud.update(elapsed);
				}
		}
		// FIXME remove ?_rubiksCube.update(elapsed);
	}

	function render():Void
	{
		// Clear the screen and prepare for this frame
		if (_ui.sceneRubiks)
		{
			_gl.clearColor(0.53, 0.81, 0.92, 1); // Clear to sky blue
		}
		else
		{
			_gl.clearColor(0, 0, 0, 1); // Clear to black
		}
		_gl.clear(_gl.COLOR_BUFFER_BIT | _gl.DEPTH_BUFFER_BIT);
		_gl.depthFunc(_gl.LESS);
		_gl.depthMask(true);
		_gl.enable(_gl.DEPTH_TEST);

		// Render the objects for this frame
		var lookAtMat = _camera.getViewMatrix();
		lookAtMat.append(projectionTransform);

		switch (setScene(_ui))
		{
			case RUBIKS:
				{
					_rubiksCube.render(_gl, lookAtMat, LIGHT_COLOR, _lightPosition, vector3DToFloat32Array(_camera.cameraPos), _ui);
				}
			case RUBIKS_WITH_LIGHT:
				{
					_rubiksCube.render(_gl, lookAtMat, LIGHT_COLOR, _lightPosition, vector3DToFloat32Array(_camera.cameraPos), _ui);
					_light.render(_gl, lookAtMat, _ui);
				}
			case CUBE_CLOUD:
				{
					var cameraPos = vector3DToFloat32Array(_camera.cameraPos);
					_cubeCloud.render(_gl, lookAtMat, LIGHT_COLOR, _lightPosition, cameraPos, _pointLights, cameraPos,
						vector3DToFloat32Array(_camera.cameraFront), _ui);
					for (i in 0...NUM_POINT_LIGHTS)
					{
						if (_ui.pointLight(i).uiPointLightEnabled.selected)
						{
							_pointLights[i].render(_gl, lookAtMat, _ui);
						}
					}
				}
		}

		// Set depthFunc to always pass so that the 2D stage rendering follows render order
		// If you don't do this the UI will render badly, missing bits like text which is
		// probably behind the buttons it's on and such like.
		_gl.depthFunc(_gl.ALWAYS);
	}

	/**
	 * Handler to progress to the next operation in the list.
	 * @param event the completion event.
	 */
	function nextOperation(event:OperationCompleteEvent):Void
	{
		trace('operation completed');
		if (operNum < operations.length - 1)
		{
			_rubiksCube.doOperation(operations[++operNum]);
		}
		else
		{
			trace('completed last operation');
		}
	}

	override function rotateModel(xOffset:Float, yOffset:Float):Void
	{
		_rubiksCube.rotate(xOffset, yOffset);
	}

	/**
	 * Handle key press events
	 * 
	 * @param event keyboard event
	 */
	override function keyHandler(event:KeyboardEvent):Void
	{
		if (!_controlsEnabled)
		{
			return;
		}

		super.keyHandler(event);

		switch (event.keyCode)
		{
			case Keyboard.R:
				// Perform rotation operation on a slice.
				operations = new Array<Operation>();
				operations.push(Operation.RotateSlice(Axis.X, 1, 90));
				operations.push(Operation.RotateSlice(Axis.Y, 1, 90));
				operations.push(Operation.RotateSlice(Axis.Z, 1, 90));
				_rubiksCube.doOperation(operations[0]);
				operNum = 0;
			// case Keyboard.P:
			// 	// Dump matrix transformation of cube vertices
			// 	var m = createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
			// 	m.append(projectionTransform);
			// 	_rubiksCube.dumpTransformVertices(m);
			default:
		}
	}

	override function getClearColor():RGBA
	{
		if (_ui.sceneRubiks)
		{
			return RGBA.create(135, 207, 235, 255); // Clear to sky blue
		}
		else
		{
			return super.getClearColor();
		}
	}
}
