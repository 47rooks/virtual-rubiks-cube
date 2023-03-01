#if html5
package scenes;

import gl.GenericShaderProgram;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLVertexArrayObject;
import lime.utils.Assets;
import lime.utils.Float32Array;
import openfl.events.Event;
import ui.UI;

/**
 * This class demonstrates instancing. It cannot run on HL, Windows. It must be run on
 * HTML5.
 */
class InstancingScene extends BaseScene
{
	// Offsets for each of the 100 squares
	var _translations:Float32Array;
	var _vao:GLVertexArrayObject;
	var _vbo:GLBuffer;
	var _instanceVbo:GLBuffer;
	var _instSquaresProgram:GenericShaderProgram;

	public function new(ui:UI)
	{
		super(ui);
	}

	function addedToStage(e:Event)
	{
        // @formatter:off
        var quadVertices = [
            // positions  colors
            -0.05,  0.05, 1.0, 0.0, 0.0,
             0.05, -0.05, 0.0, 1.0, 0.0,
            -0.05, -0.05, 0.0, 0.0, 1.0,

            -0.05,  0.05, 1.0, 0.0, 0.0,
             0.05, -0.05, 0.0, 1.0, 0.0,
             0.05,  0.05, 0.0, 0.0, 1.0
        ];
        // @formatter:on
		var quadVertexData = new Float32Array(quadVertices.length);
		for (i => e in quadVertices)
		{
			quadVertexData[i] = e;
		}

		// Initialize translations for the quads
		_translations = new Float32Array(200);
		final OFFSET = 0.1;
		var x = y = -10.0;
		var index = 0;
		while (y < 10.0)
		{
			while (x < 10.0)
			{
				_translations[index++] = x / 10.0 + OFFSET;
				_translations[index++] = y / 10.0 + OFFSET;
				x += 2.0;
			}
			y += 2.0;
			x = -10.0;
		}

		// Set up the VBO for the translations data
		_gl.bindBuffer(_gl.ARRAY_BUFFER, null);

		// Create VAO capture all buffer bindings and attribute pointers
		_vao = _gl.createVertexArray();
		_gl.bindVertexArray(_vao);
		if (_gl.getParameter(_gl.VERTEX_ARRAY_BINDING) != _vao)
		{
			trace('yes we are bound correctly');
		}

		_vbo = _gl.createBuffer();
		_gl.bindBuffer(_gl.ARRAY_BUFFER, _vbo);
		_gl.bufferData(_gl.ARRAY_BUFFER, quadVertexData, _gl.STATIC_DRAW);

		// Set up attribute pointers
		var stride = 5 * Float32Array.BYTES_PER_ELEMENT;
		_gl.enableVertexAttribArray(0);
		_gl.vertexAttribPointer(0, 2, _gl.FLOAT, false, stride, 0);

		_gl.enableVertexAttribArray(1);
		_gl.vertexAttribPointer(1, 3, _gl.FLOAT, false, stride, 2 * Float32Array.BYTES_PER_ELEMENT);

		// Bind the instance translations attribute
		_instanceVbo = _gl.createBuffer();
		_gl.bindBuffer(_gl.ARRAY_BUFFER, _instanceVbo);
		_gl.bufferData(_gl.ARRAY_BUFFER, _translations, _gl.STATIC_DRAW);

		_gl.enableVertexAttribArray(2);
		_gl.vertexAttribPointer(2, 2, _gl.FLOAT, false, 2 * Float32Array.BYTES_PER_ELEMENT, 0);
		_gl.vertexAttribDivisor(2, 1);

		// Release bindings
		_gl.bindVertexArray(null);
		_gl.bindBuffer(_gl.ARRAY_BUFFER, null);

		// Set up the program
		_instSquaresProgram = new GenericShaderProgram(_gl, Assets.getText('assets/shaders/instSquares.vert'),
			Assets.getText('assets/shaders/instSquares.frag'));
	}

	function close() {}

	function render()
	{
		_instSquaresProgram.use();

		if (_ui.quadsDiminishing)
		{
			_instSquaresProgram.setBool('quadsDiminishing', true);
		}
		else
		{
			_instSquaresProgram.setBool('quadsDiminishing', false);
		}

		_gl.bindVertexArray(_vao);

		_gl.drawArraysInstanced(_gl.TRIANGLES, 0, 6, 100);

		_gl.bindVertexArray(null);
	}
}
#end
