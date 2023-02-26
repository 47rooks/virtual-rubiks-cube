package models.logl;

import gl.OpenGLUtils.glTextureFromImageClampToEdge;
import lime.graphics.WebGL2RenderContext;
import lime.utils.Assets;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import models.logl.Model.MATERIAL_DIFFUSE;
import models.logl.Model.MATERIAL_SPECULAR;

/**
 * CubeModel is a reimplementation of the basic Cube model using the new more general Mesh
 * object. This facilitates drawing the cube by passing the shader to its draw() function.
 */
class CubeModel extends Model
{
	public function new(gl:WebGL2RenderContext, x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, scale:Float = 1.0)
	{
		super(gl, x, y, z, scale);

		final side = 1.0;

		// @formatter:off
		var verts = [ // X, Y, Z
			 side / 2.0,  side / 2, -side / 2, // Back
			-side / 2,	  side / 2, -side / 2,
			-side / 2,	 -side / 2, -side / 2,
			 side / 2,   -side / 2, -side / 2,
			-side / 2,    side / 2, -side / 2, // Left
			-side / 2,	  side / 2,  side / 2,
			-side / 2,   -side / 2,  side / 2,
			-side / 2,   -side / 2, -side / 2,
			-side / 2,    side / 2,  side / 2, // Front
			 side / 2,	  side / 2,  side / 2,
			 side / 2,   -side / 2,  side / 2,
			-side / 2,   -side / 2,  side / 2,
			 side / 2,    side / 2, -side / 2, // Right
			 side / 2,    side / 2,  side / 2,
			 side / 2,   -side / 2,  side / 2,
			 side / 2,   -side / 2, -side / 2,
			 side / 2,   -side / 2,  side / 2, // Bottom
			-side / 2,   -side / 2,  side / 2,
			-side / 2,   -side / 2, -side / 2,
			 side / 2,   -side / 2, -side / 2,
			 side / 2,    side / 2, -side / 2, // Top
			 side / 2,    side / 2,  side / 2,
			-side / 2,    side / 2,  side / 2,
			-side / 2,    side / 2, -side / 2];
		var norms = [
			// Nx, Ny, Nz
			 0.0,  0.0, -1.0, // Back
			 0.0,  0.0, -1.0,
			 0.0,  0.0, -1.0,
			 0.0,  0.0, -1.0,
			-1.0,  0.0,  0.0, // Left
			-1.0,  0.0,  0.0,
			-1.0,  0.0,  0.0,
			-1.0,  0.0,  0.0,
			 0.0,  0.0,  1.0, // Front
			 0.0,  0.0,  1.0,
			 0.0,  0.0,  1.0,
			 0.0,  0.0,  1.0,
			 1.0,  0.0,  0.0, // Right
			 1.0,  0.0,  0.0,
			 1.0,  0.0,  0.0,
			 1.0,  0.0,  0.0,
			 0.0, -1.0,  0.0, // Bottom
			 0.0, -1.0,  0.0,
			 0.0, -1.0,  0.0,
			 0.0, -1.0,  0.0,
			 0.0,  1.0,  0.0, // Top
			 0.0,  1.0,  0.0,
			 0.0,  1.0,  0.0,
			 0.0,  1.0,  0.0
		];
		var texcoords = [
			// U, V
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
			0.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
			0.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
			0.0, 1.0,
			1.0, 0.0,
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			1.0, 0.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
			0.0, 1.0
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

		// @formatter:off
		var indices:Array<UnsignedInt> = [
			 3,  2,  0, // Back
			 1,  0,  2,
			11, 10,  9, // Front
			 9,  8, 11,
			 5,  4,  7, // Left
			 7,  6,  5,
			14, 15, 12, // Right
			12, 13, 14,
			16, 18, 19, // Bottom
			16, 17, 18,
			21, 20, 23, // Top
			21, 23, 22
		];
        // @formatter:on
		_meshes.push(new Mesh(_gl, vertices, indices, loadTextures()));
	}

	function loadTextures():Array<Texture>
	{
		var rv = new Array<Texture>();

		var textureID = 0;

		for (imgPath in ["assets/openflMetalDiffuse.png", "assets/openflMetalSpecular.png"])
		{
			var img = Assets.getImage(imgPath);
			var texture = glTextureFromImageClampToEdge(_gl, img);
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
