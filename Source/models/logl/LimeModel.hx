package models.logl;

import MatrixUtils.createTranslationMatrix;
import gl.Program;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLTexture;
import models.logl.LimeMesh;
import models.logl.Mesh.Texture;
import openfl.display3D.Context3D;

final MATERIAL_DIFFUSE = "texture_diffuse";
final MATERIAL_SPECULAR = "texture_specular";

/**
 * A Model contains a complete single model, containing all meshes and textures.
 */
class LimeModel
{
	var _context:Context3D;
	var _gl:WebGLRenderContext;
	var _meshes:Array<LimeMesh>;
	var _loadedTextures:Array<Texture>;

	// World position of the model
	var _x:Float;
	var _y:Float;
	var _z:Float;

	var debugFlag = true;

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param context the OpenFL Context3D
	 * @param x x position coordinate
	 * @param y y position coordinate
	 * @param z z position coordinate
	 */
	public function new(gl:WebGLRenderContext, context:Context3D, x:Float = 0.0, y:Float = 0.0, z:Float = 0.0)
	{
		_gl = gl;
		_context = context;
		_x = x;
		_y = y;
		_z = z;
		_meshes = new Array<LimeMesh>();
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
	public function draw(program:Program, params:ProgramParameters, texture:GLTexture):Void
	{
		var matrix = createTranslationMatrix(_x, _y, _z);
		matrix.append(params.modelMatrix);
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
