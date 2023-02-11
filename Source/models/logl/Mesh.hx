package models.logl;

import gl.Program;
import haxe.ValueException;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLTexture;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import openfl.geom.Matrix3D;

/**
 * An unsigned integer implementation which throws an exception rather
 * than silently changing the input if it is negative.
 */
abstract UnsignedInt(Int)
{
	inline public function new(i:Int)
	{
		if (i < 0)
		{
			throw new ValueException('UnsigedInt must be non-negative');
		}
		this = i;
	}

	@:from
	static public function fromInt(i:Int)
	{
		return new UnsignedInt(i);
	}

	@:to
	public function toUInt():UInt
	{
		return cast(this, UInt);
	}
}

/**
 * VBO per vertex data, position, normal and texture coordinates.
 */
typedef Vertex =
{
	/**
	 * 3-element Array of x, y, z.
	 */
	var position:Array<Float>;

	/**
	 * Normal, again a 3-element Array (vec3).
	 */
	var normal:Array<Float>;

	/**
	 * Texture coordinates (u, v) as a 2-element Array.
	 */
	var texCoords:Array<Float>;
}

/**
 * Texture information
 */
typedef Texture =
{
	/**
	 * The texture id from the loaded file.
	 */
	var textureId:Int;

	/**
	 * Whether the texture is a diffuse or a specular texture.
	 * FIXME - this is actually a problem. This needs to be 
	 * rationalized in the context of GLTF2. Specifically some
	 * extension for Phong materials needs to be used and
	 * handled in this layer.
	 */
	var textureType:String;

	/**
	 * The asset path to the texture image file.
	 */
	var texturePath:String;

	/**
	 * A reference to the loaded Lime GLTexture.
	 */
	var texture:GLTexture;
}

/**
 * This class is a shim to Lime from the gltf haxelib loader. In theory a
 * variant of this class should be able to convert from an OBJ loader too,
 * and likewise for other formats.
 */
class Mesh
{
	var _gl:WebGLRenderContext;
	var _vertices:Array<Vertex>;
	var _indices:Array<UnsignedInt>;
	var _textures:Array<Texture>;
	var _glTextures:Array<GLTexture>;

	var _vertexBuffer:GLBuffer;
	var _vertexBufferData:Float32Array;
	var _indexBuffer:GLBuffer;
	var _indexBufferData:Int32Array;

	/**
	 * Constructor
	 * @param gl Lime WebGL rendering context
	 * @param vertices list of vertex attributes for this mesh
	 * @param indices list of indices for indexed drawing
	 * @param textures the textures used by the mesh
	 */
	public function new(gl:WebGLRenderContext, vertices:Array<Vertex>, indices:Array<UnsignedInt>, textures:Array<Texture>)
	{
		_gl = gl;
		_vertices = vertices;
		_indices = indices;
		_textures = textures;

		setupMesh();
	}

	/**
	 * Marshall vertex data and index data into VAO/VBO and EBO via OpenFL Context3D
	 * @param context 
	 */
	function setupMesh()
	{
		// Create vertex buffer
		_vertexBufferData = new Float32Array(_vertices.length * 8);
		for (v in 0..._vertices.length)
		{
			for (p in 0..._vertices[v].position.length)
			{
				_vertexBufferData[v * 8 + p] = _vertices[v].position[p];
			}
			for (n in 0..._vertices[v].normal.length)
			{
				_vertexBufferData[v * 8 + 3 + n] = _vertices[v].normal[n];
			}
			for (t in 0..._vertices[v].texCoords.length)
			{
				_vertexBufferData[v * 8 + 6 + t] = _vertices[v].texCoords[t];
			}
		}
		_vertexBuffer = _gl.createBuffer();

		// Create index buffer
		_indexBufferData = new Int32Array(_indices.length);
		for (i in 0..._indices.length)
		{
			_indexBufferData[i] = _indices[i];
		}
		_indexBuffer = _gl.createBuffer();

		_glTextures = new Array<GLTexture>();
		if (_textures != null)
		{
			for (t in _textures)
			{
				_glTextures.push(t.texture);
			}
		}
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
		var diffuseNr:UInt = 1;
		var specularNr:UInt = 1;
		// FIXME this should probably be passed as a list of textures to the program in an agreed order.
		// for (i in 0..._textures.length)
		// {
		// 	var number = 0;
		// 	var name = _textures[i].textureType;
		// 	if (name == 'texture_diffuse')
		// 	{
		// 		number = diffuseNr++;
		// 	}
		// 	else if (name == 'texture_specular')
		// 	{
		// 		number = specularNr++;
		// 	}
		// 	var materialU:GLUniformLocation = _gl.getUniformLocation(program._glProgram, 'material${name}${number}');
		// 	_gl.uniform1i(materialU, i);
		// 	_context.setTextureAt(i, _textures[i].texture);
		// }
		// FIXME Hacked in passing the textures. Not generalized
		if (params.modelMatrix != null)
		{
			var modelMatrix = new Matrix3D();
			modelMatrix.identity();
			modelMatrix.append(params.modelMatrix);
			modelMatrix.appendScale(64, 64, 64);
			var fullProjection = modelMatrix.clone();
			fullProjection.append(params.projectionMatrix);
			program.render({
				vbo: null,
				vertexBufferData: _vertexBufferData,
				ibo: null,
				indexBufferData: _indexBufferData,
				textures: params.textures != null ? params.textures : _glTextures,
				modelMatrix: modelMatrix,
				projectionMatrix: fullProjection,
				cameraPosition: params.cameraPosition,
				lightColor: null,
				lightPosition: null,
				directionalLight: params.directionalLight,
				pointLights: params.pointLights,
				flashlightPos: params.flashlightPos,
				flashlightDir: params.flashlightDir,
				ui: params.ui
			});
		}
		else
		{
			// FIXME This is hack to support NDC
			// quads because they do not need most
			// of the parameters. This should be refactored somehow.
			program.render({
				vbo: null,
				vertexBufferData: _vertexBufferData,
				ibo: null,
				indexBufferData: _indexBufferData,
				textures: params.textures != null ? params.textures : _glTextures,
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
			});
		}
	}
}
