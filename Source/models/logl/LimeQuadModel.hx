package models.logl;

import MatrixUtils.createTranslationMatrix;
import gl.Program;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLTexture;
import models.logl.LimeModel.MATERIAL_DIFFUSE;
import models.logl.LimeModel.MATERIAL_SPECULAR;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import openfl.Assets;
import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;

/**
 * Quad is a basic unit quad with a single object general Mesh
 * object. It accepts a texture so it can be used to display 2D bitmaps.
 */
class LimeQuadModel extends LimeModel
{
	var _modelMatrix:Matrix3D;
	var _texture:GLTexture;

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param context the OpenFL Context3D
	 * @param texturePath an Assets path to the texture image file
	 * @param modelMatrix the model matrix location and orienting this model in the world
	 */
	public function new(gl:WebGLRenderContext, context:Context3D, texturePath:String = null, modelMatrix:Matrix3D = null, yFlipTexture:Bool = false)
	{
		super(gl, context);

        // @formatter:off
		var verts = [
			// X, Y, Z
			 0.5, 0.0,  0.5,
			-0.5, 0.0,  0.5,
			-0.5, 0.0, -0.5,
			 0.5, 0.0,  0.5,
			-0.5, 0.0, -0.5,
			 0.5, 0.0, -0.5
		];
		var norms = [
			// Nx, Ny, Nz
			0.0, 0.0, 1.0,
			0.0, 0.0, 1.0,
			0.0, 0.0, 1.0,
			0.0, 0.0, 1.0,
			0.0, 0.0, 1.0,
			0.0, 0.0, 1.0
		];
		var texcoords = [
			// U, V
			1.0, 0.0,
			0.0, 0.0,
			0.0, 1.0,
			1.0, 0.0,
			0.0, 1.0,
			1.0, 1.0
		];
		var flippedTexcoords = [
			// U, V
			1.0, 1.0,
			0.0, 1.0,
			0.0, 0.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0
		];
        // @formatter:on
		var vertices = new Array<Vertex>();
		for (i in 0...Math.ceil(verts.length / 3))
		{
			vertices.push({
				position: verts.slice(i * 3, i * 3 + 3),
				normal: norms.slice(i * 3, i * 3 + 3),
				texCoords: (yFlipTexture) ? flippedTexcoords.slice(i * 2, i * 2 + 2) : texcoords.slice(i * 2, i * 2 + 2)
			});
		}

		var indices:Array<UnsignedInt> = [
			0, 1, 2,
			3, 4, 5
		];

		_modelMatrix = modelMatrix;
		if (_modelMatrix == null)
		{
			_modelMatrix = new Matrix3D();
		}
		var t:Array<Texture> = null;
		if (texturePath != null)
		{
			t = loadTexture(texturePath);
		}

		_meshes.push(new LimeMesh(_context, _gl, vertices, indices, null));
	}

	function loadTexture(imgPath:String):Array<Texture>
	{
		var rv = new Array<Texture>();

		var textureID = 0;

		var tData = Assets.getBitmapData(imgPath);
		var texture = _context.createRectangleTexture(tData.width, tData.height, BGRA, false);
		texture.uploadFromBitmapData(tData);
		rv.push({
			textureId: textureID,
			textureType: textureID == 0 ? MATERIAL_DIFFUSE : MATERIAL_SPECULAR,
			texturePath: imgPath,
			texture: texture
		});
		textureID++;
		rv.push({
			textureId: textureID,
			textureType: textureID == 0 ? MATERIAL_DIFFUSE : MATERIAL_SPECULAR,
			texturePath: imgPath,
			texture: texture
		});

		_loadedTextures = rv;
		return rv;
	}

	public function setTexture(texture:GLTexture):Void
	{
		_texture = texture;
	}

	override public function draw(program:Program, params:ProgramParameters, texture:GLTexture):Void
	{
		var m = _modelMatrix.clone();
		m.append(params.modelMatrix);
		var matrix = createTranslationMatrix(_x, _y, _z);
		matrix.append(m);
		var meshParams = {
			vbo: null,
			ibo: null,
			textures: null,
			modelMatrix: matrix,
			projectionMatrix: params.projectionMatrix,
			cameraPosition: params.cameraPosition,
			lightColor: null,
			lightPosition: null,
			directionalLight: params.directionalLight,
			pointLights: params.pointLights,
			flashlightPos: params.flashlightPos,
			flashlightDir: params.flashlightDir,
			ui: params.ui
		}
		for (m in _meshes)
		{
			m.draw(program, meshParams, texture);
		}
	}
}