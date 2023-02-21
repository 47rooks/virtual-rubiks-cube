package gl;

import gl.Program.ProgramParameters;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Assets;
import lime.utils.Float32Array;

/**
 * The framebuffer program demonstrates the use of a framebuffer for render the scene to a texture and applying post-processing effects to it.
 */
class NDCQuadProgram extends Program
{
	// GL variables
	/* Image uniform used for the case where the cube face displays an image */
	private var _programImageUniform:GLUniformLocation;

	/* Vertex attributes for vertex and texture coordinates. */
	private var _programVertexAttribute:Int;
	private var _programTextureAttribute:Int;

	/* Postprocessing Effects */
	private var _programInversionEffectUniform:GLUniformLocation;
	private var _programGrayscaleEffectUniform:GLUniformLocation;
	private var _programSharpenEffectUniform:GLUniformLocation;
	private var _programBlurEffectUniform:GLUniformLocation;
	private var _programEdgeDetectionEffectUniform:GLUniformLocation;

	/**
	 * Constructor
	 * @param gl A WebGL render context
	 */
	public function new(gl:WebGL2RenderContext):Void
	{
		super(gl);

		var vertexSource = Assets.getText("assets/shaders/ndcquad.vert");
		var fragmentSource = #if !desktop "precision mediump float;" + #end
		Assets.getText("assets/shaders/framebuffer.frag");

		createGLSLProgram(vertexSource, fragmentSource);
		getShaderVarLocations();
	}

	public function getShaderVarLocations():Void
	{
		// Get references to GLSL attributes
		_programVertexAttribute = _gl.getAttribLocation(_glProgram, "aPosition");

		_programTextureAttribute = _gl.getAttribLocation(_glProgram, "aTexCoord");

		// Texture uniform
		_programImageUniform = _gl.getUniformLocation(_glProgram, "texture1");

		// Postprocessing effects
		_programInversionEffectUniform = _gl.getUniformLocation(_glProgram, "uInversion");
		_programGrayscaleEffectUniform = _gl.getUniformLocation(_glProgram, "uGrayscale");
		_programSharpenEffectUniform = _gl.getUniformLocation(_glProgram, "uSharpen");
		_programBlurEffectUniform = _gl.getUniformLocation(_glProgram, "uBlur");
		_programEdgeDetectionEffectUniform = _gl.getUniformLocation(_glProgram, "uEdgeDetection");
	}

	public function render(params:ProgramParameters)
	{
		// // Image texture
		_gl.uniform1i(_programImageUniform, 0);
		_gl.activeTexture(_gl.TEXTURE0);
		_gl.bindTexture(_gl.TEXTURE_2D, params.textures[0]);
		_gl.activeTexture(0);

		// Apply GL calls to submit the cube data to the GPU
		// Bind vertex buffer
		_gl.bindBuffer(_gl.ARRAY_BUFFER, params.vbo);

		// Set up attribute pointers
		var stride = 8 * Float32Array.BYTES_PER_ELEMENT;
		_gl.enableVertexAttribArray(_programVertexAttribute);
		_gl.vertexAttribPointer(_programVertexAttribute, 2, _gl.FLOAT, false, stride, 0);

		_gl.enableVertexAttribArray(_programTextureAttribute);
		_gl.vertexAttribPointer(_programTextureAttribute, 2, _gl.FLOAT, false, stride, 6 * Float32Array.BYTES_PER_ELEMENT);

		// Bind index data
		_gl.bindBuffer(_gl.ELEMENT_ARRAY_BUFFER, params.ebo);

		// Postprocessing variables
		_gl.uniform1i(_programInversionEffectUniform, params.ui.uiInversion.selected ? 1 : 0);
		_gl.uniform1i(_programGrayscaleEffectUniform, params.ui.uiGrayscale.selected ? 1 : 0);
		_gl.uniform1i(_programSharpenEffectUniform, params.ui.uiSharpen.selected ? 1 : 0);
		_gl.uniform1i(_programBlurEffectUniform, params.ui.uiBlur.selected ? 1 : 0);
		_gl.uniform1i(_programEdgeDetectionEffectUniform, params.ui.uiEdgeDetection.selected ? 1 : 0);

		_gl.drawElements(_gl.TRIANGLES, params.numIndexes, _gl.UNSIGNED_INT, 0);
	}
}
