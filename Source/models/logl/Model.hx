package models.logl;

import MatrixUtils.createTranslationMatrix;
import gl.Program;
import lime.graphics.WebGLRenderContext;
import models.logl.Mesh;

final MATERIAL_DIFFUSE = "texture_diffuse";
final MATERIAL_SPECULAR = "texture_specular";

/**
 * A Model contains a complete single model, containing all meshes and textures.
 */
class Model
{
	var _gl:WebGLRenderContext;
	var _meshes:Array<Mesh>;
	var _loadedTextures:Array<Texture>;

	// World position of the model
	var _x:Float;
	var _y:Float;
	var _z:Float;

	var debugFlag = true;

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param x x position coordinate
	 * @param y y position coordinate
	 * @param z z position coordinate
	 */
	public function new(gl:WebGLRenderContext, x:Float = 0.0, y:Float = 0.0, z:Float = 0.0)
	{
		_gl = gl;
		_x = x;
		_y = y;
		_z = z;
		_meshes = new Array<Mesh>();
		_loadedTextures = new Array<Texture>();
	}

	/**
	 * Draw the mesh with the provided program and parameters.
	 * @param program the program to render with
	 * @param params the program parameters
	 * 	the following ProgramParameters fields are required
	 * 		- vbo
	 * 		- ibo
	 * 		- textures
	 * 			- 0 the diffuse light map
	 * 			- 1 the specular light map
	 * 		- modelMatrix
	 * 		- projectionMatrix
	 *		- cameraPosition
	 *		- directionalLight
	 *		- pointLights
	 *		- flashlighPos
	 *		- flashlightDir
	 * 		- ui
	 */
	public function draw(program:Program, params:ProgramParameters):Void
	{
		var matrix = createTranslationMatrix(_x, _y, _z);
		matrix.append(params.modelMatrix);
		var meshParams = {
			vbo: null,
			vertexBufferData: null,
			ibo: null,
			indexBufferData: null,
			textures: params.textures,
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
			m.draw(program, meshParams);
		}
	}
}
