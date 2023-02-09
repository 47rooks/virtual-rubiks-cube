package models.logl;

import gl.OpenGLUtils.glTextureFromImageRepeat;
import lime.graphics.WebGLRenderContext;
import lime.utils.Assets;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import models.logl.Model.MATERIAL_DIFFUSE;
import models.logl.Model.MATERIAL_SPECULAR;

/**
 * PlaneModel is a basic plan with a single object general Mesh
 * object. This facilitates drawing the plane by passing the shader to its draw() function.
 */
class PlaneModel extends Model
{
	public function new(gl:WebGLRenderContext, x:Float = 0.0, y:Float = 0.0, z:Float = 0.0)
	{
		super(gl, x, y, z);

        // @formatter:off
		var verts = [
			// X, Y, Z
			 5.0, -0.5,  5.0,
			-5.0, -0.5,  5.0,
			-5.0, -0.5,	-5.0,
			 5.0, -0.5,  5.0,
			-5.0, -0.5, -5.0,
			 5.0, -0.5,	-5.0
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
			2.0, 0.0,
			0.0, 0.0,
			0.0, 2.0,
			2.0, 0.0,
			0.0, 2.0,
			2.0, 2.0
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

		_meshes.push(new Mesh(_gl, vertices, indices, loadTextures()));
	}

	function loadTextures():Array<Texture>
	{
		var rv = new Array<Texture>();

		var textureID = 0;

		for (imgPath in ["assets/metal.png", "assets/metal.png"])
		{
			var img = Assets.getImage(imgPath);
			var texture = glTextureFromImageRepeat(_gl, img);
			rv.push({
				textureId: textureID,
				textureType: textureID == 0 ? MATERIAL_DIFFUSE : MATERIAL_SPECULAR,
				texturePath: imgPath,
				texture: texture
			});
			textureID++;
		}

		_loadedTextures = rv;
		return rv;
	}
}
