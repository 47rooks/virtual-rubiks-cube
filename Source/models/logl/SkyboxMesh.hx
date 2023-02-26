package models.logl;

import gl.Program.ProgramParameters;
import gl.Program;
import lime.graphics.WebGL2RenderContext;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;

/**
 * The SkyboxMesh is a special subclass with a draw method which is distinct
 * from that used by either NDC or regular meshes.
 */
class SkyboxMesh extends Mesh
{
	/**
	 * Constructor
	 * @param gl Lime WebGL rendering context
	 * @param vertices list of vertex attributes for this mesh
	 * @param indices list of indices for indexed drawing
	 * @param textures the textures used by the mesh
	 */
	public function new(gl:WebGL2RenderContext, vertices:Array<Vertex>, indices:Array<UnsignedInt>, textures:Array<Texture>)
	{
		super(gl, vertices, indices, textures);
	}

	/**
	 * Draw the mesh with the provided program and parameters.
	 * @param program the program to render with
	 * @param params the program parameters
	 * 	the following ProgramParameters fields are required
	 * 		- modelMatrix
	 * 		- projectionMatrix
	 * 		- ui
	 * 
	 * The textures and VBO, EBO are setup during construction and passed to the Program here.
	 */
	override public function draw(program:Program, params:ProgramParameters):Void
	{
		program.render({
			vbo: vbo,
			vertexBufferData: null,
			ebo: ebo,
			numIndexes: _indices.length,
			indexBufferData: null,
			textures: _glTextures,
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
		});
	}
}
