package scenes;

import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createRotationMatrix;
import MatrixUtils.vector3DToFloat32Array;
import gl.FramebufferProgram;
import gl.ModelLoadingProgram;
import gl.NDCQuadProgram;
import lights.PointLight;
import lime.graphics.Image;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLTexture;
import lime.utils.Assets;
import lime.utils.Float32Array;
import models.logl.CubeModel;
import models.logl.Model;
import models.logl.NDCQuad;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import ui.UI;

/**
 * The Framebuffer scene demostrates the use of a framebuffer to render a scene to a texture which is then
 * use to texture a quad.
 */
class FramebufferScene extends BaseScene
{
	var _models:Array<Model>;
	var _framebufferProgram:FramebufferProgram;
	var _modelLoadingProgram:ModelLoadingProgram;
	var _nDCQuadProgram:NDCQuadProgram;

	var _locs:Array<Array<Float>>;
	var _grass:Image;

	var _pointLights:Array<PointLight>;

	// GL Render buffer object
	var _framebuffer:GLFramebuffer;
	var _rbo:GLBuffer;
	var _colorTex:GLTexture;

	public static final NUM_POINT_LIGHTS = 4;

	public function new(ui:UI)
	{
		super(ui);

        // @formatter:off
		/**
		 * This is a quick hack to make the positions accessible. The position should be a model
         * attribute.
		 */
		_locs = [[0.0, 0.0, 0.0],
			     [2.0, 5.0, -15.0],
			     [-1.5, -2.2, -2.5],
				 [-3.8, -2.0, -2.5],
			     [2.4, -0.4, -3.5],
			     [-1.7, 3.0, -7.5],
			     [1.3, -2.0, -2.5],
			     [1.5, 2.0, -2.5],
			     [1.5, 0.2, -1.5],
			     [-1.3, 1.0, -1.5]
                ];
        // @formatter:on
		_models = new Array<Model>();
	}

	function addedToStage(e:Event)
	{
		_camera = new Camera(new Vector3D(0, 0, 200), new Vector3D(0, 1, 0));
		// Compute projection matrix
		projectionTransform = createPerspectiveProjection(_camera.fov, 640 / 480, 100, 1000);

		for (l in _locs)
		{
			_models.push(new CubeModel(_gl, l[0], l[1], l[2]));
		}

		_modelLoadingProgram = new ModelLoadingProgram(_gl);
		_framebufferProgram = new FramebufferProgram(_gl);
		_nDCQuadProgram = new NDCQuadProgram(_gl);
		_grass = Assets.getImage("assets/grass.png");

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

		// Create the framebuffer
		_framebuffer = _gl.createFramebuffer();
		_gl.bindFramebuffer(_gl.FRAMEBUFFER, _framebuffer);
		// Create the color buffer
		_colorTex = _gl.createTexture();
		_gl.bindTexture(_gl.TEXTURE_2D, _colorTex); // Bind the color texture buffer and set properties
		_gl.texImage2D(_gl.TEXTURE_2D, 0, _gl.RGBA, 1280, 960, 0, _gl.RGBA, _gl.UNSIGNED_BYTE, null);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MIN_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MAG_FILTER, _gl.LINEAR);

		// Unbind the texture buffer
		_gl.bindTexture(_gl.TEXTURE_2D, 0);

		// Attach the color buffer
		_gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_2D, _colorTex, 0);

		// Create the depth and stencil buffer
		var depthStencilBuffer = _gl.createRenderbuffer();
		_gl.bindRenderbuffer(_gl.RENDERBUFFER, depthStencilBuffer);
		_gl.renderbufferStorage(_gl.RENDERBUFFER, _gl.DEPTH_STENCIL, 1280, 960);
		_gl.bindRenderbuffer(_gl.RENDERBUFFER, 0);
		// Attach the depth/stencil buffer
		_gl.framebufferRenderbuffer(_gl.FRAMEBUFFER, _gl.DEPTH_STENCIL_ATTACHMENT, _gl.RENDERBUFFER, depthStencilBuffer);

		// Check that there are no errors
		if (_gl.checkFramebufferStatus(_gl.FRAMEBUFFER) != _gl.FRAMEBUFFER_COMPLETE)
		{
			trace('framebuffer not complete');
			_gl.bindFramebuffer(_gl.FRAMEBUFFER, 0);
			return;
		}
		_gl.bindFramebuffer(_gl.FRAMEBUFFER, 0);
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

		renderCubeCloud(cameraPos, lookAtMat, lightDirection);

		// var grassTex = glTextureFromImageClampToEdge(_gl, _grass);
		_gl.bindFramebuffer(_gl.FRAMEBUFFER, _framebuffer);

		_gl.clearColor(0.53, 0.81, 0.92, 1.0);
		_gl.clear(_gl.COLOR_BUFFER_BIT | _gl.DEPTH_BUFFER_BIT);
		_gl.disable(_gl.STENCIL_TEST);
		_gl.depthFunc(_gl.LESS);
		_gl.depthMask(true);
		_gl.enable(_gl.DEPTH_TEST);

		// Now render the scene again - this time to the framebuffer we just created
		renderCubeCloud(cameraPos, lookAtMat, lightDirection);

		// Revert to the original framebuffer
		_gl.bindFramebuffer(_gl.FRAMEBUFFER, 0);

		_gl.disable(_gl.DEPTH_TEST);

		// Create a quad model and render to that
		var quad = new NDCQuad(_gl);
		_nDCQuadProgram.use();
		quad.draw(_nDCQuadProgram, {
			vbo: null,
			vertexBufferData: null,
			ibo: null,
			numIndexes: 0,
			indexBufferData: null,
			textures: [_colorTex],
			modelMatrix: null,
			projectionMatrix: null,
			cameraPosition: null,
			lightColor: null,
			lightPosition: null,
			directionalLight: null,
			pointLights: null,
			flashlightPos: null,
			flashlightDir: null,
			ui: _ui
		});

		_gl.enable(_gl.DEPTH_TEST);
	}

	private function renderCubeCloud(cameraPos:Float32Array, lookAtMat:Matrix3D, lightDirection:Float32Array):Void
	{
		// Draw initial cube cloud
		for (m in _models)
		{
			m.draw(_modelLoadingProgram, {
				vbo: null,
				vertexBufferData: null,
				ibo: null,
				numIndexes: 0,
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
	}
}
