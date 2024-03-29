package models.logl;

import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import gl.Program;
import lime.graphics.WebGL2RenderContext;
import models.logl.Mesh;

final MATERIAL_DIFFUSE = "texture_diffuse";
final MATERIAL_SPECULAR = "texture_specular";

/**
 * A Model contains a complete single model, containing all meshes and textures.
 */
class Model
{
	var _gl:WebGL2RenderContext;
	var _meshes:Array<Mesh>;
	var _loadedTextures:Array<Texture>;

	// World position of the model
	var _x:Float;
	var _y:Float;
	var _z:Float;
	var _scale:Float;

	var debugFlag = true;

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param x x position coordinate
	 * @param y y position coordinate
	 * @param z z position coordinate
	 * @param scale the scaling factor
	 */
	public function new(gl:WebGL2RenderContext, x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, scale:Float = 1.0)
	{
		_gl = gl;
		_x = x;
		_y = y;
		_z = z;
		_scale = scale;
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
		var matrix = createScaleMatrix(_scale, _scale, _scale);
		matrix.append(createTranslationMatrix(_x, _y, _z));
		matrix.append(params.modelMatrix);
		var meshParams = {
			vbo: null,
			vertexBufferData: null,
			ebo: null,
			numIndexes: 0,
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
