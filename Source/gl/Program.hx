package gl;

import gl.OpenGLUtils.glCreateProgram;
import haxe.ValueException;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLProgram;
import openfl.display3D.Context3D;

class Program
{
	// Graphics contexts
	var _gl:WebGLRenderContext;
	var _context:Context3D;

	// GL variables
	public var _glProgram:GLProgram;

	public function new(gl:WebGLRenderContext, context:Context3D)
	{
		_gl = gl;
		_context = context;
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
}
