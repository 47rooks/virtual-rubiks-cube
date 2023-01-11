package models.logl;

import MatrixUtils.createTranslationMatrix;
import gl.ModelLoadingProgram;
import gl.OutliningProgram;
import lights.PointLight;
import lime.graphics.WebGLRenderContext;
import lime.utils.Float32Array;
import models.logl.Mesh.Texture;
import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;
import ui.UI;

final MATERIAL_DIFFUSE = "texture_diffuse";
final MATERIAL_SPECULAR = "texture_specular";

/**
 * A Model contains a complete single model, containing all meshes and textures.
 */
class Model
{
	var _context:Context3D;
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
		_meshes = new Array<Mesh>();
		_loadedTextures = new Array<Texture>();
	}

	public function draw(program:ModelLoadingProgram, modelMatrix:Matrix3D, projectionMatrix:Matrix3D, lightDirection:Float32Array,
			cameraPosition:Float32Array, pointLights:Array<PointLight>, flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI):Void
	{
		var matrix = createTranslationMatrix(_x, _y, _z);
		matrix.append(modelMatrix);
		for (m in _meshes)
		{
			m.draw(program, matrix, projectionMatrix, lightDirection, cameraPosition, pointLights, flashlightPos, flashlightDir, ui);
		}
	}

	public function drawOutline(program:OutliningProgram, modelMatrix:Matrix3D, projectionMatrix:Matrix3D, lightDirection:Float32Array,
			cameraPosition:Float32Array, pointLights:Array<PointLight>, flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI):Void
	{
		var matrix = createTranslationMatrix(_x, _y, _z);
		matrix.append(modelMatrix);
		for (m in _meshes)
		{
			m.drawOutline(program, matrix, projectionMatrix, lightDirection, cameraPosition, pointLights, flashlightPos, flashlightDir, ui);
		}
	}
}
