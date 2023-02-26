package models.logl;

import gl.Program;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLTexture;
import lime.utils.Assets;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import models.logl.Model.MATERIAL_DIFFUSE;

/**
 * SkyboxModel implements a Model subclass unique to the cubemap. There is no need
 * for normals or texture attributes.
 */
class SkyboxModel extends Model
{
	public function new(gl:WebGL2RenderContext, skyboxTexture:GLTexture)
	{
		super(gl);

		final side = 2.0;

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

		// @formatter:on
		var vertices = new Array<Vertex>();
		for (i in 0...Math.ceil(verts.length / 3))
		{
			vertices.push({
				position: verts.slice(i * 3, i * 3 + 3),
				normal: [],
				texCoords: []
			});
		}

		// @formatter:off
		var indices:Array<UnsignedInt> = [
			3,  2,  0, // Back
			1,  0,  2,
			5,  4,  7, // Left
			7,  6,  5,
			11, 10,  9, // Front
			 9,  8, 11,
			14, 15, 12, // Right
			12, 13, 14,
			16, 18, 19, // Bottom
			16, 17, 18,
			21, 20, 23, // Top
			21, 23, 22
		];
        // @formatter:on
		var texArr = new Array<Texture>();
		texArr.push({
			textureId: 0,
			textureType: MATERIAL_DIFFUSE,
			texturePath: 'skybox',
			texture: skyboxTexture
		});
		_meshes.push(new SkyboxMesh(_gl, vertices, indices, texArr));
	}


	override public function draw(program:Program, params:ProgramParameters):Void
	{
		var meshParams = {
			vbo: null,
			vertexBufferData: null,
			ebo: null,
			numIndexes: 0,
			indexBufferData: null,
			textures: params.textures,
			modelMatrix: params.modelMatrix,
			projectionMatrix: params.projectionMatrix,
			cameraPosition: null,
			lightColor: null,
			lightPosition: null,
			directionalLight: null,
			pointLights: null,
			flashlightPos: null,
			flashlightDir: null,
			ui: params.ui
		};
		for (m in _meshes)
		{
			m.draw(program, meshParams);
		}
	}
}
