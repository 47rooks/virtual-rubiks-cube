package models.logl;

import gl.Program;
import lime.graphics.WebGLRenderContext;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import models.logl.Model.MATERIAL_DIFFUSE;
import models.logl.Model.MATERIAL_SPECULAR;
import openfl.Assets;
import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;

/**
 * Quad is a basic unit quad with a single object general Mesh
 * object. It accepts a texture so it can be used to display 2D bitmaps.
 */
class QuadModel extends Model
{
	var _modelMatrix:Matrix3D;

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param context the OpenFL Context3D
	 * @param texturePath an Assets path to the texture image file
	 * @param modelMatrix the model matrix location and orienting this model in the world
	 */
	public function new(gl:WebGLRenderContext, context:Context3D, texturePath:String, modelMatrix:Matrix3D = null)
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
        // @formatter:on
		var vertices = new Array<Vertex>();
		for (i in 0...Math.ceil(verts.length / 3))
		{
			vertices.push({
				position: verts.slice(i * 3, i * 3 + 3),
				normal: norms.slice(i * 3, i * 3 + 3),
				texCoords: texcoords.slice(i * 2, i * 2 + 2)
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
		_meshes.push(new Mesh(_context, _gl, vertices, indices, loadTexture(texturePath)));
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

	override public function draw(program:Program, params:ProgramParameters):Void
	{
		var m = _modelMatrix.clone();
		m.append(params.modelMatrix);
		params.modelMatrix = m;
		super.draw(program, params);
	}
}
