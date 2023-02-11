package models.logl;

import gl.Program;
import lime.graphics.WebGLRenderContext;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;

/**
 * A quad created in Normalized Device Coordinates for render textures without model, view or projection matrices. For HUDs and such. Currently the size is fixed to the upper right core of the viewport.
 */
class NDCQuad extends Model
{
	public function new(gl:WebGLRenderContext)
	{
		super(gl);

        // @formatter:off
		var verts = [
			// X, Y
			 0.0, 1.0,
			 0.0, 0.0,
			 1.0, 0.0,
			 0.0, 1.0,
			 1.0, 0.0,
			 1.0, 1.0
		];
		var texcoords = [
			// U, V
			0.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			0.0, 1.0,
			1.0, 0.0,
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
		for (i in 0...Math.ceil(verts.length / 2))
		{
			vertices.push({
				position: verts.slice(i * 2, i * 2 + 2),
				normal: [],
				texCoords: texcoords.slice(i * 2, i * 2 + 2)
			});
		}

		var indices:Array<UnsignedInt> = [
			0, 1, 2,
			3, 4, 5
		];

		_meshes.push(new Mesh(_gl, vertices, indices, null));
	}

	override public function draw(program:Program, params:ProgramParameters):Void
	{
		var meshParams = {
			vbo: null,
			vertexBufferData: null,
			ibo: null,
			indexBufferData: null,
			textures: params.textures,
			modelMatrix: null,
			projectionMatrix: null,
			cameraPosition: null,
			lightColor: null,
			lightPosition: null,
			directionalLight: null,
			pointLights: null,
			flashlightPos: null,
			flashlightDir: null,
			ui: params.ui
		}
		for (m in _meshes)
		{
			m.draw(program, meshParams);
		}
	}
}
