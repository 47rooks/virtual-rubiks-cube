package gl;

import gl.OpenGLUtils.glCreateProgram;
import haxe.ValueException;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLProgram;
import lime.utils.Float32Array;

/**
 * This is an initial cut at a generic shader program based on the design
 * in LearnOpenGL. Setters are provided for the various uniform types,
 * though currently only one is available so far. A use() function is
 * provided to make this program the active one.
 */
class GenericShaderProgram
{
	// Graphics contexts
	var _gl:WebGL2RenderContext;

	// GL variables
	public var _glProgram:GLProgram;

	public function new(gl:WebGL2RenderContext, vertex:String, fragment:String):Void
	{
		_gl = gl;
		createGLSLProgram(vertex, fragment);
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

	public function setVec2(name:String, value:Float32Array):Void
	{
		var loc = _gl.getUniformLocation(_glProgram, name);
		_gl.uniform2fv(loc, value, 0);
	}

	public function setBool(name:String, value:Bool):Void
	{
		var loc = _gl.getUniformLocation(_glProgram, name);
		_gl.uniform1i(loc, value == true ? 1 : 0);
	}
}
