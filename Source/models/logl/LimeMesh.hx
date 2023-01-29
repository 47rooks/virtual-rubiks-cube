package models.logl;

import gl.FramebufferProgram;
import gl.Program;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLTexture;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.geom.Matrix3D;

/**
 * Texture information
 */
typedef LimeTexture =
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
	 * A reference to the loaded OpenFL GLTexture.
	 */
	var texture:GLTexture;
}

/**
 * This class is a shim to OpenFL from the gltf haxelib loader. In theory a
 * variant of this class should be able to convert from an OBJ loader too,
 * and likewise for other formats.
 * 
 * This is a Lime rather than OpenFL version.
 * FIXME It requires clean up so that all these classes are Lime based only.
 */
class LimeMesh
{
	var _context:Context3D;
	var _gl:WebGLRenderContext;
	var _vertices:Array<Vertex>;
	var _indices:Array<UnsignedInt>;
	var _textures:Array<LimeTexture>;

	// Internal buffer structs
	public var _glVertexBuffer:Float32Array;
	public var _glIndexBuffer:IndexBuffer3D;

	var _vertexBuffer:GLBuffer;
	var _vertexBufferData:Float32Array;
	var _indexBuffer:GLBuffer;
	var _indexBufferData:Int32Array;

	/**
	 * Constructor
	 * @param context OpenFL Context3D context object
	 * @param gl Lime WebGL rendering context
	 * @param vertices list of vertex attributes for this mesh
	 * @param indices list of indices for indexed drawing
	 * @param textures the textures used by the mesh
	 */
	public function new(context:Context3D, gl:WebGLRenderContext, vertices:Array<Vertex>, indices:Array<UnsignedInt>, textures:Array<LimeTexture>)
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
	function setupMesh()
	{
		if (_glVertexBuffer != null)
		{
			return;
		}

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
		// _glVertexBuffer = _context.createVertexBuffer(_vertices.length, 8, STATIC_DRAW);
		// _glVertexBuffer.uploadFromVector(vertexData, 0, _vertices.length * 8);
		_vertexBuffer = _gl.createBuffer();
		// _gl.bindBuffer(_gl.ARRAY_BUFFER, _vertexBuffer);
		// _gl.bufferData(_gl.ARRAY_BUFFER, vertexData, _gl.STATIC_DRAW);

		// Create index buffer
		_indexBufferData = new Int32Array(_indices.length);
		for (i in 0..._indices.length)
		{
			_indexBufferData[i] = _indices[i];
		}
		// _glIndexBuffer = _context.createIndexBuffer(indexData.length, STATIC_DRAW);
		// _glIndexBuffer.uploadFromVector(indexData, 0, indexData.length);
		_indexBuffer = _gl.createBuffer();
		// _gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, _indexBuffer);
		// _gl.bufferData(_gl.ELEMENT_ARRAY_BUFFER, indexData, _gl.STATIC_DRAW);
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
		modelMatrix.append(params.modelMatrix);
		modelMatrix.appendScale(64, 64, 64);
		var fullProjection = modelMatrix.clone();
		fullProjection.append(params.projectionMatrix);
		// if (_textures.length != 2 || _textures[0].texture == null || _textures[1].texture == null)
		// {
		// 	trace('problem with textures');
		// }
		cast(program, FramebufferProgram).setTexture(texture, _vertexBuffer, _vertexBufferData, _indexBuffer, _indexBufferData);
		program.render({
			vbo: null,
			ibo: null,
			textures: null,
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
}
