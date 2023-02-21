package models.logl;

import gl.Program;
import lime.graphics.WebGL2RenderContext;
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
	public function new(gl:WebGL2RenderContext)
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
		_meshes.push(new SkyboxMesh(_gl, vertices, indices, loadSkyboxTexture()));
	}

	private function loadSkyboxTexture():Array<Texture>
	{
		var rv = new Array<Texture>();
		var faces = [
			"assets/skybox/right.jpg",
			"assets/skybox/left.jpg",
			"assets/skybox/top.jpg",
			"assets/skybox/bottom.jpg",
			"assets/skybox/front.jpg",
			"assets/skybox/back.jpg"
		];

		_gl.activeTexture(_gl.TEXTURE0);
		var tex = _gl.createTexture();
		_gl.bindTexture(_gl.TEXTURE_CUBE_MAP, tex);
		for (i => path in faces)
		{
			var img = Assets.getImage(path);
			_gl.texImage2D(_gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, _gl.RGBA, img.buffer.width, img.buffer.height, 0, _gl.RGBA, _gl.UNSIGNED_BYTE,
				img.buffer.data);
		}
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_MIN_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_MAG_FILTER, _gl.LINEAR);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_WRAP_S, _gl.CLAMP_TO_EDGE);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_WRAP_T, _gl.CLAMP_TO_EDGE);
		_gl.texParameteri(_gl.TEXTURE_CUBE_MAP, _gl.TEXTURE_WRAP_R, _gl.CLAMP_TO_EDGE);

		_gl.activeTexture(0);

		rv.push({
			textureId: 0,
			textureType: MATERIAL_DIFFUSE,
			texturePath: 'skybox',
			texture: tex
		});

		return rv;
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
