package scenes;

import MatrixUtils.createPerspectiveProjection;
import MatrixUtils.createRotationMatrix;
import MatrixUtils.vector3DToFloat32Array;
import gl.FramebufferProgram;
import gl.ModelLoadingProgram;
import lights.PointLight;
import lime.graphics.Image;
import lime.graphics.opengl.GLTexture;
import lime.utils.Assets;
import lime.utils.Float32Array;
import models.logl.CubeModel;
import models.logl.Model;
import models.logl.QuadModel;
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
	var _locs:Array<Array<Float>>;
	var _grass:Image;

	var _pointLights:Array<PointLight>;

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

		/* Lime way of doing things */

		// Create a framebuffer
		var framebuffer = _gl.createFramebuffer();
		_gl.bindFramebuffer(_gl.FRAMEBUFFER, framebuffer);

		// Create the color buffer
		var colorTex = _gl.createTexture();
		_gl.bindTexture(_gl.TEXTURE_2D, colorTex); // Bind the color texture buffer and set properties
		_gl.texImage2D(_gl.TEXTURE_2D, 0, _gl.RGBA, 1280, 960, 0, _gl.RGBA, _gl.UNSIGNED_BYTE, null);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MIN_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MAG_FILTER, _gl.LINEAR);

		// Unbind the texture buffer
		_gl.bindTexture(_gl.TEXTURE_2D, 0);

		// Attach the color buffer
		_gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0, _gl.TEXTURE_2D, colorTex, 0);

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

		var grassTex = getTextureFromImage(_grass);

		_gl.clearColor(0.53, 0.81, 0.92, 0);
		_gl.clear(_gl.COLOR_BUFFER_BIT | _gl.DEPTH_BUFFER_BIT);
		_gl.disable(_gl.STENCIL_TEST);
		_gl.depthFunc(_gl.LESS);
		_gl.depthMask(true);
		_gl.enable(_gl.DEPTH_TEST);

		// Now render the scene again - this time to the framebuffer we just created
		renderCubeCloud(cameraPos, lookAtMat, lightDirection);
		// _gl.enable(_gl.DEPTH_TEST);

		// Revert to the original framebuffer
		_gl.bindFramebuffer(_gl.FRAMEBUFFER, 0);

		// Create a quad model and render to that
		_framebufferProgram.use();
		var m = createRotationMatrix(-90, Vector3D.X_AXIS);
		m.appendTranslation(0.0, 0.0, 0.501);

		var quad = new QuadModel(_gl, null, m, true);
		quad.draw(_framebufferProgram, {
			vertexBufferData: null,
			indexBufferData: null,
			textures: [colorTex],
			modelMatrix: _sceneRotation,
			projectionMatrix: lookAtMat,
			cameraPosition: cameraPos,
			lightColor: null,
			lightPosition: null,
			directionalLight: lightDirection,
			pointLights: null,
			flashlightPos: cameraPos,
			flashlightDir: vector3DToFloat32Array(_camera.cameraFront),
			ui: _ui
		});

		_gl.enable(_gl.DEPTH_TEST);
		// FB _gl.deleteFramebuffer(framebuffer);
	}

	private function getTextureFromImage(image:Image):GLTexture
	{
		var glTexture = _gl.createTexture();
		_gl.bindTexture(_gl.TEXTURE_2D, glTexture);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_WRAP_S, _gl.CLAMP_TO_EDGE);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_WRAP_T, _gl.CLAMP_TO_EDGE);
		_gl.texImage2D(_gl.TEXTURE_2D, 0, _gl.RGBA, image.buffer.width, image.buffer.height, 0, _gl.RGBA, _gl.UNSIGNED_BYTE, image.data);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MAG_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MIN_FILTER, _gl.LINEAR);
		_gl.bindTexture(_gl.TEXTURE_2D, null);
		return glTexture;
	}

	private function renderCubeCloud(cameraPos:Float32Array, lookAtMat:Matrix3D, lightDirection:Float32Array):Void
	{
		// Draw initial cube cloud
		for (m in _models)
		{
			m.draw(_modelLoadingProgram, {
				vertexBufferData: null,
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
