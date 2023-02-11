package gl;

import gl.OpenGLUtils.glCreateProgram;
import haxe.ValueException;
import lights.PointLight;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import openfl.geom.Matrix3D;
import ui.UI;

/**
 * ProgramParameters is a container type to carry all possible render function parameters. The exact
 * parameters that must be set is determined by the specific Program subclass.
 */
typedef ProgramParameters =
{
	/**
	 * Vertex buffer object
	 */
	var vbo:GLBuffer;

	/**
	 * The vertex buffer data. The attributes present for each vertex will be determined by the
	 * specific program. This is bound to the VAO in the program.
	 */
	var vertexBufferData:Float32Array;

	/**
	 * Index buffer object
	 */
	var ibo:GLBuffer;

	/**
	 * Number of indexes in the ibo to render.
	 */
	var numIndexes:Int;

	/**
	 * The index buffer data. Whether indexed drawing is required or not will be determined by the
	 * specific program. This is bound to the EBO in the program.
	 */
	var indexBufferData:Int32Array;

	/**
	 * An array of textures.
	 * FIXME ultimately this should be an array of TextureInfo objects so that we can follow
	 * a convention as to what textures are diffuse or specular or otherwise.
	 */
	var textures:Array<GLTexture>;

	/**
	 * The model matrix to apply to the model to place it properly oriented and position in the world.
	 */
	var modelMatrix:Matrix3D;

	/**
	 * The projection matrix to use.
	 */
	var projectionMatrix:Matrix3D;

	/**
	 * The camera position.
	 * FIXME This should be a camera object
	 */
	var cameraPosition:Float32Array;

	/**
	 * The light color.
	 * This is used in the simplest light models only.
	 */
	var lightColor:Float32Array;

	/**
	 * The light position.
	 * This is used in the simplest light models only.
	 */
	var lightPosition:Float32Array;

	/**
	 * The direction vector of the directional light.
	 * FIXME  This should be a directional light object
	 */
	var directionalLight:Float32Array;

	var pointLights:Array<PointLight>;

	/**
	 * Flashlight position.
	 * FIXME this should be part of a flashlight object
	 */
	var flashlightPos:Float32Array;

	/**
	 * Flashlight direction vector
	 * FIXME this should be part of a flashlight object 
	 */
	var flashlightDir:Float32Array;

	/**
	 * The UI instance.
	 */
	var ui:UI;
}

/**
 * Base GL program class.
 */
abstract class Program
{
	// Graphics contexts
	var _gl:WebGLRenderContext;

	// GL variables
	public var _glProgram:GLProgram;

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 */
	public function new(gl:WebGLRenderContext)
	{
		_gl = gl;
	}

	/**
	 * Make this program the current one in the GL context.
	 */
	public function use():Void
	{
		_gl.useProgram(_glProgram);
	}

	/**
	 * Create a GLSL program compiling the supplied shader source and linking the program.
	 * @param vertexSource vertex shader source
	 * @param fragmentSource fragment shader source
	 */
	function createGLSLProgram(vertexSource:String, fragmentSource:String):Void
	{
		_glProgram = glCreateProgram(_gl, vertexSource, fragmentSource);
		if (_glProgram == null)
		{
			throw new ValueException('compilation failed, check accompanying errors');
		}
	}

	/**
	 * Render the object specified by the parameters.
	 * The exact data provided in the params parameter
	 * provides all the information required by the
	 * Program to render an object. All fields are
	 * optional but the program subclass may and 
	 * probably should implement checks.
	 * @param params the program data.
	 */
	public abstract function render(params:ProgramParameters):Void;
}
