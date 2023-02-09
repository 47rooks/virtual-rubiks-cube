/**
 * OpenGLUtils provides a collection of GL helper functions.
 */

package gl;

import lime.graphics.Image;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLTexture;

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

/**
 * Create a Lime texture from an Image.
 * @param gl the WebGLRenderContext
 * @param image the Lime image to create the texture from
 * @param wrap_s OpenGL texture S wrap option
 * @param wrap_t  OpenGL texture T wrap option
 * @return GLTexture
 */
function glTextureFromImage(gl:WebGLRenderContext, image:Image, wrap_s:Int, wrap_t:Int):GLTexture
{
	var glTexture = gl.createTexture();
	gl.bindTexture(gl.TEXTURE_2D, glTexture);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap_s);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap_t);
	gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, image.buffer.width, image.buffer.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.bindTexture(gl.TEXTURE_2D, null);
	return glTexture;
}

/**
 * Helper function to create a texture repeating in both axes.
 * @param gl the WebGLRenderContext
 * @param image the Lime image to create the texture from
 * @return GLTexture
 */
function glTextureFromImageRepeat(gl:WebGLRenderContext, image:Image):GLTexture
{
	return glTextureFromImage(gl, image, gl.REPEAT, gl.REPEAT);
}

/**
 * Helper function to create a texture clamping to both axes.
 * @param gl the WebGLRenderContext 
 * @param image the Lime image to create the texture from
 * @return GLTexture
 */
function glTextureFromImageClampToEdge(gl:WebGLRenderContext, image:Image):GLTexture
{
	return glTextureFromImage(gl, image, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE);
}
