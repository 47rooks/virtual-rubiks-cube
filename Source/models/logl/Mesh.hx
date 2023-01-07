package models.logl;

import gl.ModelLoadingProgram;
import haxe.ValueException;
import lights.PointLight;
import lime.graphics.WebGLRenderContext;
import lime.utils.Float32Array;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Matrix3D;
import ui.UI;

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
	 * A reference to the loaded OpenFL RectangleTexture.
	 */
	var texture:RectangleTexture;
}

/**
 * This class is a shim to OpenFL from the gltf haxelib loader. In theory a
 * variant of this class should be able to convert from an OBJ loader too,
 * and likewise for other formats.
 */
class Mesh
{
	var _context:Context3D;
	var _gl:WebGLRenderContext;
	var _vertices:Array<Vertex>;
	var _indices:Array<UnsignedInt>;
	var _textures:Array<Texture>;

	// Internal buffer structs
	public var _glVertexBuffer:VertexBuffer3D;
	public var _glIndexBuffer:IndexBuffer3D;

	/**
	 * Constructor
	 * @param context OpenFL Context3D context object
	 * @param gl Lime WebGL rendering context
	 * @param vertices list of vertex attributes for this mesh
	 * @param indices list of indices for indexed drawing
	 * @param textures the textures used by the mesh
	 */
	public function new(context:Context3D, gl:WebGLRenderContext, vertices:Array<Vertex>, indices:Array<UnsignedInt>, textures:Array<Texture>)
	{
		_context = context;
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
	@:access(openfl.display3D.VertexBuffer3D.__data)
	function setupMesh()
	{
		if (_glVertexBuffer != null)
		{
			return;
		}

		// Create vertex buffer
		var vertexData = new Vector<Float>();
		for (v in _vertices)
		{
			for (p in v.position)
			{
				vertexData.push(p);
			}
			for (n in v.normal)
			{
				vertexData.push(n);
			}
			for (t in v.texCoords)
			{
				vertexData.push(t);
			}
		}
		_glVertexBuffer = _context.createVertexBuffer(_vertices.length, 8, STATIC_DRAW);
		_glVertexBuffer.uploadFromVector(vertexData, 0, _vertices.length * 8);
		// Create index buffer
		var indexData = new Vector<UInt>();
		for (i in _indices)
		{
			indexData.push(i);
		}
		_glIndexBuffer = _context.createIndexBuffer(indexData.length, STATIC_DRAW);
		_glIndexBuffer.uploadFromVector(indexData, 0, indexData.length);
	}

	public function draw(program:ModelLoadingProgram, rotationMatrix:Matrix3D, projectionMatrix:Matrix3D, lightDirection:Float32Array,
			cameraPosition:Float32Array, pointLights:Array<PointLight>, flashlightPos:Float32Array, flashlightDir:Float32Array, ui:UI)
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
		var modelMatrix = new Matrix3D();
		modelMatrix.identity();
		modelMatrix.append(rotationMatrix);
		modelMatrix.appendScale(64, 64, 64);
		var fullProjection = modelMatrix.clone();
		fullProjection.append(projectionMatrix);
		if (_textures.length != 2 || _textures[0].texture == null || _textures[1].texture == null)
		{
			trace('problem with texturess');
		}
		program.render(modelMatrix, fullProjection, lightDirection, cameraPosition, _glVertexBuffer, _glIndexBuffer, _textures[0].texture,
			_textures[1].texture, pointLights, flashlightPos, flashlightDir, ui);
	}
}
