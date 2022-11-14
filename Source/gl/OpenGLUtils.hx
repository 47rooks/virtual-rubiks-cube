/**
 * OpenGLUtils provides a collection of GL helper functions.
 */

package gl;

import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;

/**
 * Create a GL shader.
 * 
 * @param gl the GL rendering context
 * @param source GLSL source text
 * @param type type of shader to compile, usually gl.VERTEX_SHADER or gl.FRAGMENT_SHADER
 * @return GLShader
 */
function glCreateShader(gl:WebGLRenderContext, source:String, type:Int):GLShader
{
	var shader = gl.createShader(type);
	gl.shaderSource(shader, source);
	gl.compileShader(shader);

	if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0)
	{
		trace(gl.getShaderInfoLog(shader));
		return null;
	}

	return shader;
}

/**
 * Create a GL program with vertex and fragment shaders.
 * @param gl the GL rendering context
 * @param vertexSource vertex shader GLSL source
 * @param fragmentSource fragment shader GLSL source
 * @return Null<GLProgram> the compiled and linked program or null if unsuccessful.
 */
function glCreateProgram(gl:WebGLRenderContext, vertexSource:String, fragmentSource:String):Null<GLProgram>
{
	var vs = glCreateShader(gl, vertexSource, gl.VERTEX_SHADER);
	var fs = glCreateShader(gl, fragmentSource, gl.FRAGMENT_SHADER);

	if (vs == null || fs == null)
	{
		return null;
	}

	var program = gl.createProgram();
	gl.attachShader(program, vs);
	gl.attachShader(program, fs);

	gl.deleteShader(vs);
	gl.deleteShader(fs);

	gl.linkProgram(program);

	if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
	{
		trace(gl.getProgramInfoLog(program));
		trace("VALIDATE_STATUS: " + gl.getProgramParameter(program, gl.VALIDATE_STATUS));
		trace("ERROR: " + gl.getError());
		return null;
	}

	return program;
}
