package models.logl;

import gl.OpenGLUtils.glTextureFromImageClampToEdge;
import gltf.GLTF;
import gltf.schema.TGLTF;
import gltf.schema.TGLTFID;
import gltf.types.MeshPrimitive;
import gltf.types.Node;
import haxe.io.Path;
import lime.graphics.WebGL2RenderContext;
import lime.utils.Assets;
import models.logl.Mesh.Texture;
import models.logl.Mesh.UnsignedInt;
import models.logl.Mesh.Vertex;
import models.logl.Model.MATERIAL_DIFFUSE;
import models.logl.Model.MATERIAL_SPECULAR;

/**
 * A model loaded from a GLTF artifact.
 */
class GLTFModel extends Model
{
	var _gltfRaw:TGLTF; // JSON file
	var _gltfObject:GLTF; // bin file
	var _directory:String;

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param gltfFilePath an Assets path to the model JSON file
	 * @param gltfBinFilePath an Assets path to the model .bin file
	 */
	public function new(gl:WebGL2RenderContext, gltfFilePath:String, gltfBinFilePath:String)
	{
		super(gl);

		loadModel(gltfFilePath, gltfBinFilePath);
	}

	function loadModel(gltfFilePath:String, gltfBinFilePath:String):Void
	{
		var gltfFile = Assets.getText(gltfFilePath);
		var gltfBinFile = Assets.getBytes(gltfBinFilePath);
		_gltfRaw = GLTF.parse(gltfFile);
		_gltfObject = GLTF.load(_gltfRaw, [gltfBinFile]);
		_directory = Path.directory(gltfFilePath);

		// Process all data to extract and marshal the data for the meshes
		processScene(_gltfObject);
	}

	/**
	 * Process each scene - initially just do scene 0
	 * FIXME - note gltf does not support the scene attribute. In fact GLTF object is documented as representing a glTF scene. Nonetheless it seems to get all scenes - just doesn't support the default scene attribute.
	 * FIXME - MeshPrimitive does not have a mode field
	 * FIXME - MeshPrimitive does not support morph targets
	 * FIXME - BufferView does not handle byteStride. Seems we don't need it for this though
	 * @param model a GLTF 
	 */
	function processScene(model:GLTF):Void
	{
		var scene = 0;
		var s = model.scenes[scene];
		for (n in s.nodes)
		{
			processNode(n);
		}
		// for (n in s.nodes[0].children)
		// {
		// 	processMesh(n.mesh);
		// }
	}

	function processNode(node:Node):Void
	{
		if (node.mesh != null)
		{
			processMesh(node.mesh);
		}
		if (node.children.length > 0)
		{
			for (childNode in node.children)
			{
				processNode(childNode);
			}
		}
	}

	function processMesh(mesh:gltf.types.Mesh):Void
	{
		if (mesh.primitives == null)
			trace('no primitives on ${mesh.name}');
		for (p in mesh.primitives)
		{
			var m = processMeshPrimitive(p, mesh.name);
			if (m != null)
			{
				_meshes.push(m);
			}
			else
			{
				trace('got a null mesh');
			}
		}
	}

	function processMeshPrimitive(primitive:MeshPrimitive, meshName:String):Null<Mesh>
	{
		var positions = primitive.getFloatAttributeValues('POSITION');
		var normals = primitive.getFloatAttributeValues('NORMAL');
		var texcoords = primitive.getFloatAttributeValues('TEXCOORD_0');
		if (debugFlag && texcoords[0] == 0.0)
		{
			trace('texcoords(${meshName})=${texcoords}');
		}
		if (positions.length != normals.length || Math.ceil(positions.length / 3) != Math.ceil(texcoords.length / 2))
		{
			trace('loading aborted - positions, normals and texcoords arrays are different lengths\n'
				+ '    positions=${positions.length}, normals=${normals.length}, texcoods=${texcoords.length}');
			return null;
		}

		// Get the per-vertex data - position, normals and texture coordinates
		var vertexData = new Array<Vertex>();
		for (i in 0...Math.ceil(positions.length / 3))
		{
			var p = new Array<Float>();
			p = p.concat([positions[3 * i], positions[3 * i + 1], positions[3 * i + 2]]);
			var n = new Array<Float>();
			n = n.concat([normals[3 * i], normals[3 * i + 1], normals[3 * i + 2]]);
			var t = new Array<Float>();
			t = t.concat([texcoords[2 * i], texcoords[2 * i + 1]]);
			// trace('t=$t');
			vertexData.push({position: p, normal: n, texCoords: t});
		}
		// Get the indexes for indexed drawing
		var indexData = new Array<UnsignedInt>();
		for (i in primitive.getIndexValues())
		{
			indexData.push(i);
		}

		// Get the textures
		var diffuseMaps = loadMaterialTextures(primitive.material, MATERIAL_DIFFUSE);
		var specularMaps = loadMaterialTextures(primitive.material, MATERIAL_SPECULAR);
		var textures = new Array<Texture>();
		textures.push(diffuseMaps);
		textures.push(specularMaps);
		// trace('diffusetx=${diffuseMaps.textureId}, ${diffuseMaps.textureType}, ${diffuseMaps.texturePath}');
		// trace('speculartx=${specularMaps.textureId}, ${specularMaps.textureType}, ${specularMaps.texturePath}');
		return new Mesh(_gl, vertexData, indexData, textures);
	}

	/**
	 * Load the material texture into the cache and return a Texture object
	 * @param materialId the material id
	 * @param type 
	 * @return Texture
	 */
	function loadMaterialTextures(materialId:TGLTFID, type:String):Texture
	{
		var textureID = 0;
		for (i in _gltfRaw.images)
		{
			var path = Path.join([_directory, i.uri]);
			var alreadyLoaded = false;
			for (t in _loadedTextures)
			{
				if (t.texturePath == path)
				{
					alreadyLoaded = true;
				}
			}
			if (!alreadyLoaded)
			{
				var img = Assets.getImage(path);
				var texture = glTextureFromImageClampToEdge(_gl, img);
				_loadedTextures.push({
					textureId: textureID,
					textureType: textureID == 0 ? MATERIAL_DIFFUSE : MATERIAL_SPECULAR,
					texturePath: path,
					texture: texture
				});
			}
			textureID++;
		}
		/* In order to process materials with diffuse/specular textures gltf support for
		 * the KHR_materials_pbrSpecularGlossiness extension is required. For the moment
		 * I will just load the textures directly from the images element and cache their
		 * IDs.
		 * FIXME add proper material support
		 */
		/*
			var m = _gltfRaw.materials[materialId];
			switch (type)
			{
				case MATERIAL_DIFFUSE:
					if (m.extensions != null)
					{
						trace('m.extensions:diffuse:${m.extensions}');
					}
				case MATERIAL_SPECULAR:
					if (m.extensions != null)
					{
						trace('m.extensions:specular:${m.extensions}');
					}
				default:
			}
		 */
		return _loadedTextures[type == MATERIAL_DIFFUSE ? 0 : 1];
	}
}
