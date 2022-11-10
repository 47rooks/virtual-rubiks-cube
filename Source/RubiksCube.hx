package;

import Color.BLACK;
import Color.BLUE;
import Color.GREEN;
import Color.ORANGE;
import Color.RED;
import Color.WHITE;
import Color.YELLOW;
import Cube.ColorSpec;
import MatrixUtils.createScaleMatrix;
import MatrixUtils.createTranslationMatrix;
import MatrixUtils.matrix3DToFloat32Array;
import OpenGLUtils.glCreateProgram;
import lime.graphics.Image;
import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.RGBA;
import lime.utils.Assets;
import lime.utils.Float32Array;
import openfl.display3D.Context3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * Component cube positional data.
 * FIXME This duplicates the same named elements of CubeData. Please fix
 */
typedef CubeDataPos =
{
	/**
	 * Unique id for this cube
	 */
	var id:String;

	/**
	 * The x position, 0-based, for this cube. Position is defined in units of cubes.
	 */
	var x:Int;

	/**
	 * The y position, 0-based, for this cube. Position is defined in units of cubes.
	 */
	var y:Int;

	/**
	 * The z position, 0-based, for this cube. Position is defined in units of cubes.
	 */
	var z:Int;
}

/**
 * Component cube data and current transformation matrices.
 */
typedef CubeData =
{
	/**
	 * Unique id for this cube
	 */
	var id:String;

	/**
	 * The x position, 0-based, for this cube. Position is defined in units of cubes.
	 */
	var x:Int;

	/**
	 * The y position, 0-based, for this cube. Position is defined in units of cubes.
	 */
	var y:Int;

	/**
	 * The z position, 0-based, for this cube. Position is defined in units of cubes.
	 */
	var z:Int;

	/**
	 * Reference to the Cube object for this component unit cube.
	 */
	var cube:Cube;

	/**
	 * The scale matrix for this component cube. This makes the cube the right size for this Rubik's cube.
	 */
	var scaleMatrix:Matrix3D;

	/**
	 * The rotation matrix for this component cube. Usually this is an identity matrix - no rotation.
	 */
	var rotationMatrix:Matrix3D;

	/**
	 * The translation matrix for this component cube. This places the component at the right place in the Rubik's cube.
	 */
	var translationMatrix:Matrix3D;

	/**
	 * The model matrix for this component cube. This is the multiplication of scale, rotation and translation matrices.
	 */
	var modelMatrix:Matrix3D;
}

/**
 * Axis defines an enum for each axis, X, Y and Z and provides the corresponding vector.
 */
enum abstract Axis(Int)
{
	final X = 0;
	final Y = 1;
	final Z = 2;
	static final vectors = [0 => new Vector3D(1, 0, 0), 1 => new Vector3D(0, 1, 0), 2 => new Vector3D(0, 0, 1)];

	/**
	 * Get the vector representing this axis.
	 */
	@:to
	public function toVector()
	{
		return vectors[this];
	}
}

/**
 * Operations that may be performed on the cube. It is expected that any operation may take many
 * update cycles to complete.
 */
enum Operation
{
	/**
	 * Rotate a slice by the specified angle. The slice is defined by the axis it rotates around, 
	 * and the number of cube units along that axis. This in a 3x3 cube slice (Axis X, ordinal 1) is
	 * the slice that projects from the middle of the front face of the cube to the middle of the back.
	 */
	RotateSlice(axis:Axis, ordinal:Int, angle:Float);
}

/**
 * A class defining a Rubik's cube of a specific number of cubes side length, and size per component cube.
 */
class RubiksCube
{
	final ROW_LEN = 3;
	final SIDE:Float;
	final START_OFFSET:Float;

	final ROTATION_SENSITIVTY = 0.5;

	// GL interface variables
	private var _faceTexture:RectangleTexture;
	private var _glProgram:GLProgram;
	private var _glProgramTextureAttribute:Int;
	private var _glTexture:GLTexture;
	private var _programImageUniform:GLUniformLocation;
	private var _programMatrixUniform:GLUniformLocation;
	private var _programModelMatrixUniform:GLUniformLocation;
	private var _programTextureAttribute:Int;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	private var _programNormalAttribute:Int;
	private var _programLightColorUniform:GLUniformLocation;
	private var _programLightPositionUniform:GLUniformLocation;
	private var _programViewerPositionUniform:GLUniformLocation;

	// Cube face texture image
	var _faceImageData:Image;

	// Cube data
	var _x:Int;
	var _y:Int;
	var _z:Int;
	var _cubes:Map<String, CubeData>;

	// Current operation
	final OPERATION_DURATION = 2; // seconds to perform operation
	var _operation:Null<Operation>;
	var _inProgress:Bool;
	var _incAngle:Float;
	var _accAngle:Float;
	var _rotMatrix:Null<Matrix3D>;
	var _affectedCubes:Array<String>;

	// Vectors and Matrices
	var _cubeRotation:Matrix3D;
	var _yaw:Float;
	var _pitch:Float;

	// Scene reference
	var _scene:Scene;

	/**
	 * Constructor
	 * 
	 * @param x x position to place cube at
	 * @param y y position to place cube at
	 * @param z z position to place cube at
	 * @param scene the owning Scene object, for event dispatch
	 */
	public function new(x:Int, y:Int, z:Int, scene:Scene, gl:WebGLRenderContext, context:Context3D)
	{
		SIDE = 64; // FIXME this may need to be a constructor parameter
		START_OFFSET = -(ROW_LEN * SIDE) / 2 + SIDE / 2;
		trace('start_offset=${START_OFFSET}, SIDE=${SIDE}');
		_x = x;
		_y = y;
		_z = z;
		_scene = scene;

		// Load texture
		_faceImageData = Assets.getImage("assets/openfl.png");
		// _faceTexture = _context.createRectangleTexture(_faceImageData.width, _faceImageData.height, BGRA, false);
		// _faceTexture.uploadFromBitmapData(_faceImageData);

		_cubes = createCubes(context);

		// Initialize operation data
		_operation = null;
		_incAngle = 0;
		_accAngle = 0;
		_inProgress = false;
		_affectedCubes = new Array<String>();

		// Initialize vectors and matrices
		_yaw = -90;
		_pitch = 0;
		_cubeRotation = new Matrix3D();

		initializeGl(gl, context);
	}

	/**
	 * Create the required number of cubes with correct colors and positioning data.
	 * 
	 * @param gl the GL render context to use
	 * @return Map<String, CubeData>
	 */
	function createCubes(context:Context3D):Map<String, CubeData>
	{
		var cubes = new Map<String, CubeData>();
		for (i in 0...ROW_LEN)
		{ // X front face - left -> right
			for (j in 0...ROW_LEN)
			{ // Y front face - bottom -> top
				for (k in 0...ROW_LEN)
				{ // Z front face 0 - front -> back
					// skip interior cubes
					if (i > 0 && i < ROW_LEN - 1 && j > 0 && j < ROW_LEN - 1 && k > 0 && k < ROW_LEN - 1)
					{
						continue;
					}
					var cs = createColorSpec(i, j, k, ROW_LEN);
					var c:Cube = new Cube(cs, context);
					var scaleMatrix = createScaleMatrix(SIDE, SIDE, SIDE);
					var rotationMatrix = new Matrix3D();
					rotationMatrix.identity();
					var translationMatrix = createTranslationMatrix(START_OFFSET + i * SIDE, START_OFFSET + j * SIDE, START_OFFSET + k * SIDE);
					var modelMatrix = new Matrix3D();
					modelMatrix.append(scaleMatrix);
					modelMatrix.append(rotationMatrix);
					modelMatrix.append(translationMatrix);
					var cd:CubeData = {
						id: '$i' + '$j' + '$k',
						x: i,
						y: j,
						z: k,
						cube: c,
						scaleMatrix: scaleMatrix,
						rotationMatrix: rotationMatrix,
						translationMatrix: translationMatrix,
						modelMatrix: modelMatrix
					};
					cubes[cd.id] = cd;
				}
			}
		}
		return cubes;
	}

	/**
	 * Comppute a color specification for a cube in the specified location.
	 * For now all cubes are assumed to have the same orientation.
	 * 
	 * @param x x coordinate 0-sideLen-1
	 * @param y y coordinate 0-sideLen-1
	 * @param z z coordinate 0-sideLen-1
	 * @param sideLen the number of component cubes per side
	 * @return ColorSpec
	 */
	function createColorSpec(x:Int, y:Int, z:Int, sideLen:Int):ColorSpec
	{
		final COLORS:ColorSpec = {
			front: RED,
			back: ORANGE,
			top: WHITE,
			bottom: YELLOW,
			left: GREEN,
			right: BLUE
		};

		var rv:ColorSpec = {
			front: BLACK,
			back: BLACK,
			top: BLACK,
			bottom: BLACK,
			left: BLACK,
			right: BLACK
		};

		if (x == 0)
		{
			rv.left = COLORS.left;
		}
		if (x == sideLen - 1)
		{
			rv.right = COLORS.right;
		}
		if (y == 0)
		{
			rv.bottom = COLORS.bottom;
		}
		if (y == sideLen - 1)
		{
			rv.top = COLORS.top;
		}
		if (z == 0)
		{
			rv.back = COLORS.back;
		}
		if (z == sideLen - 1)
		{
			rv.front = COLORS.front;
		}

		return rv;
	}

	public function doOperation(operation:Operation):Void
	{
		if (_inProgress)
		{
			// FIXME - this needs to throw an exception or queue the operation or error or something.
			//         also a completion callback model like tween would be nice
			return;
		}
		_operation = operation;
		_inProgress = true;
	}

	public function update(elapsed:Float)
	{
		if (_inProgress)
		{
			switch (_operation)
			{
				case RotateSlice(axis, ordinal, angle):
					if (_incAngle == 0.0)
					{
						_incAngle = angle * 0.016 / OPERATION_DURATION;
						// Copy cube references for all affected cubes into _affectedCubes
						_affectedCubes = getSliceCubes(axis, ordinal);
						trace('len affectedcubes=${_affectedCubes.length}');
					}
					_accAngle += _incAngle;
					if (_accAngle >= angle)
					{
						// Action is completed. Do these things:
						//    1. burn in rotation matrix for full angle
						//    2. reset operation variables
						//    3. mark inProgress false
						for (c in _affectedCubes)
						{
							var cube = _cubes.get(c);
							cube.modelMatrix.appendRotation(angle, axis.toVector());
							// FIXME assumes 90 rotation
						}
						// Set new location value
						updateLocations(axis, angle);

						_incAngle = 0;
						_accAngle = 0;
						_operation = null;
						_inProgress = false;
						_rotMatrix = null;
						_affectedCubes = new Array<String>();

						// Send a completion event
						var evt = new OperationCompleteEvent(OperationCompleteEvent.OPERATION_COMPLETE_EVENT, 0);
						_scene.dispatchEvent(evt);
					}
					else
					{
						_rotMatrix = new Matrix3D();
						_rotMatrix.appendRotation(_accAngle, axis.toVector());
					}
			}
		}
	}

	/**
	 * Compare two integer value.
	 * 
	 * @param a first value to compare
	 * @param b second value to compare
	 * @return Int -1 if a < b, 0 if they are equal and 1 if b > b
	 */
	function comp(a:Int, b:Int):Int
	{
		if (a < b)
		{
			return -1;
		}
		else if (a == b)
		{
			return 0;
		}
		else
		{
			return 1;
		}
	}

	/**
	 * Given an angle or rotation and the Axis compute the new locations for each component cube
	 * @param axis the axis the slice rotates about
	 * @param angle angle rotated - currently the assumption is that this is either +90 or -90
	 */
	function updateLocations(axis:Axis, angle:Float):Void
	{
		// sort the cubes
		var sortedCubes = new Array<CubeData>();
		var tmpCubes = new Array<CubeData>();
		var cubesToUpdate = _affectedCubes.copy();
		var cubesToRm = new Array<String>();
		switch (axis)
		{
			case X:
				// Do first side
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.z == 0)
					{
						trace('z=0: cid(${cube.id}):adding to tmpCubes');
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(a.y, b.y);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do second side
				var kv = tmpCubes[tmpCubes.length - 1].y;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.y == kv)
					{
						trace('y=${kv} cid(${cube.id}):adding to tmpCubes');
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(a.z, b.z);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do third side
				var kv = tmpCubes[tmpCubes.length - 1].z;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.z == kv)
					{
						trace('z=${kv} cid(${cube.id}):adding to tmpCubes');
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(b.y, a.y);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do fourth side
				var kv = tmpCubes[tmpCubes.length - 1].y;
				trace('final y kv=${kv}');
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.y == kv)
					{
						trace('y=${kv} cid(${cube.id}):adding to tmpCubes');
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(b.z, a.z);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();

				if (cubesToUpdate.length != sortedCubes.length)
				{
					trace('length mismatch after sorting. cubesToUpdate.length=${cubesToUpdate.length}, sortedCubes.length=${sortedCubes.length}');
				}
				trace('cubesToUpdate=${cubesToUpdate}');
				for (c in sortedCubes)
				{
					trace('${c.id}');
				}
			case Y:
				// Do first side
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.x == 0)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(a.z, b.z);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do second side
				var kv = tmpCubes[tmpCubes.length - 1].z;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.z == kv)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(a.x, b.x);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do third side
				var kv = tmpCubes[tmpCubes.length - 1].x;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.x == kv)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(b.z, a.z);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do fourth side
				var kv = tmpCubes[tmpCubes.length - 1].z;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.z == kv)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(b.x, a.x);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();

				if (cubesToUpdate.length != sortedCubes.length)
				{
					trace('length mismatch after sorting. cubesToUpdate.length=${cubesToUpdate.length}, sortedCubes.length=${sortedCubes.length}');
				}
				trace('cubesToUpdate=${cubesToUpdate}');
				for (c in sortedCubes)
				{
					trace('${c.id}');
				}
			case Z:
				// Do first side
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.y == 0)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(a.x, b.x);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do second side
				var kv = tmpCubes[tmpCubes.length - 1].x;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.x == kv)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(a.y, b.y);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do third side
				var kv = tmpCubes[tmpCubes.length - 1].y;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.y == kv)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(b.x, a.x);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();
				// Do fourth side
				var kv = tmpCubes[tmpCubes.length - 1].x;
				tmpCubes = new Array<CubeData>();
				for (c in cubesToUpdate)
				{
					var cube = _cubes.get(c);
					if (cube.x == kv)
					{
						tmpCubes.push(cube);
						cubesToRm.push(c);
					}
				}
				tmpCubes.sort((a, b) ->
				{
					return comp(b.y, a.y);
				});
				sortedCubes = sortedCubes.concat(tmpCubes);
				for (r in cubesToRm)
				{
					cubesToUpdate.remove(r);
				}
				cubesToRm = new Array<String>();

				if (cubesToUpdate.length != sortedCubes.length)
				{
					trace('length mismatch after sorting. cubesToUpdate.length=${cubesToUpdate.length}, sortedCubes.length=${sortedCubes.length}');
				}
				trace('cubesToUpdate=${cubesToUpdate}');

				trace('dump before location update');
				dumpSlice(sortedCubes);
		}

		// Now that we have an array of moved cubes in the order they appear in the ring, update their positions

		var tmpCubePos = new Array<CubeDataPos>();
		if (angle > 0)
		{
			// forward rotation
			// Copy first sides worth of coordinates
			for (i in 0...ROW_LEN - 1)
			{
				tmpCubePos.push({
					id: sortedCubes[i].id,
					x: sortedCubes[i].x,
					y: sortedCubes[i].y,
					z: sortedCubes[i].z
				});
			}
			// Now move each sides worth of data back
			var dest = 0;
			for (i in ROW_LEN - 1...sortedCubes.length)
			{
				sortedCubes[dest].x = sortedCubes[i].x;
				sortedCubes[dest].y = sortedCubes[i].y;
				sortedCubes[dest].z = sortedCubes[i].z;
				dest++;
			}
			// Finally put the saved first side's data into the last side
			var dest = sortedCubes.length - ROW_LEN + 1;
			for (i in 0...tmpCubePos.length)
			{
				sortedCubes[dest].x = tmpCubePos[i].x;
				sortedCubes[dest].y = tmpCubePos[i].y;
				sortedCubes[dest].z = tmpCubePos[i].z;
				dest++;
			}
		}
		else
		{
			// backward rotation
			// Copy first sides worth of coordinates
			var i = sortedCubes.length - 1;
			while (i > sortedCubes.length - ROW_LEN)
			{
				// for (i in sortedCubes.length - 1...sortedCubes.length - ROW_LEN) {
				tmpCubePos.push({
					id: sortedCubes[i].id,
					x: sortedCubes[i].x,
					y: sortedCubes[i].y,
					z: sortedCubes[i].z
				});
				i--;
			}
			// Now move each sides worth of data forward
			var dest = sortedCubes.length - 1;
			i = sortedCubes.length - ROW_LEN;
			while (i >= 0)
			{
				// for (i in sortedCubes.length - ROW_LEN...0) {
				sortedCubes[dest].x = sortedCubes[i].x;
				sortedCubes[dest].y = sortedCubes[i].y;
				sortedCubes[dest].z = sortedCubes[i].z;
				dest--;
				i--;
			}
			// Finally put the saved last side's data into the first side
			var dest = 0;
			var i = tmpCubePos.length - 1;
			while (i >= 0)
			{
				// for (i in tmpCubePos.length...0) {
				sortedCubes[dest].x = tmpCubePos[i].x;
				sortedCubes[dest].y = tmpCubePos[i].y;
				sortedCubes[dest].z = tmpCubePos[i].z;
				dest++;
				i--;
			}
		}

		trace('dump after location update');
		dumpSlice(sortedCubes);
	}

	/**
	 * Create a list of component cube ids given a slice identified by Axis and ordinal
	 * 
	 * @param axis the Axis
	 * @param ordinal the coordinate on the Axis that defines the slice
	 * @return Array<String>
	 */
	function getSliceCubes(axis:Axis, ordinal:Int):Array<String>
	{
		var rv = new Array<String>();
		for (c in _cubes)
		{
			switch (axis)
			{
				case X:
					if (c.x == ordinal)
					{
						rv.push(c.id);
					}
				case Y:
					if (c.y == ordinal)
					{
						rv.push(c.id);
					}
				case Z:
					if (c.z == ordinal)
					{
						rv.push(c.id);
					}
			}
		}
		return rv;
	}

	/**
	 * Initialize GL variables, shaders and program.
	 * 
	 * @param gl the GL render context
	 */
	function initializeGl(gl:WebGLRenderContext, context:Context3D):Void
	{
		_glTexture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, _glTexture);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, _faceImageData.buffer.width, _faceImageData.buffer.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, _faceImageData.data);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

		gl.vertexAttribPointer(_glProgramTextureAttribute, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 2 * Float32Array.BYTES_PER_ELEMENT);

		// Create GLSL program object
		createGLSLProgram(gl);
	}

	function createGLSLProgram(gl:WebGLRenderContext):Void
	{
		var vertexSource = "attribute vec4 aPosition;
			attribute vec2 aTexCoord;
			varying vec2 vTexCoord;
			
			attribute vec4 aColor;
			varying vec4 vColor;
	
			attribute vec3 aNormal;
			varying vec3 vNormal;
			
			varying vec3 vFragPos;

			uniform mat4 uMatrix;
			uniform mat4 uModel;
			
			void main(void) {
				vTexCoord = aTexCoord;
				vColor = aColor / vec4(0xff);

				// Transform normals to world space to handle cube transformations.
				// Proper normal matrix not required as we only uniform scale
				// the cubes. If we did non-uniform we would need a normal matrix.
				vNormal = (uModel * vec4(aNormal, 0.0)).xyz;
				
				gl_Position = uMatrix * aPosition;
				vFragPos = (uModel * aPosition).xyz;
			}";

		var fragmentSource = #if !desktop "precision mediump float;" + #end

		"varying vec2 vTexCoord;
				varying vec4 vColor;
				uniform sampler2D uImage0;

				uniform vec3 uLightPos;   // Light position
				uniform vec3 uLight;      // Light color
				varying vec3 vNormal;     // Object normals
				varying vec3 vFragPos;    // World position of fragment

				uniform vec3 uViewerPos;   // Camera position

				void main(void)
				{
					/* Compute ambient lighting */
					float ambientStrength = 0.1;
					vec3 lightColor = uLight.rgb / 255.0;
					vec3 ambient =  lightColor.rgb * vec3(ambientStrength);

					/* Apply texture */
					vec4 tColor = texture2D(uImage0, vTexCoord);
					vec3 cColor = tColor.rgb * vColor.rgb;
					if (tColor.a == 0.0) {
						cColor = vColor.rgb;
					}
					
					/* Compute diffuse lighting */
					vec3 norm = normalize(vNormal);
					vec3 lightDirection = normalize(uLightPos - vFragPos);
					float diffuse = max(dot(norm, lightDirection), 0.0);

					/* Compute specular lighting */
					float specularStrength = 0.75;
					vec3 viewerDir = normalize(uViewerPos.xyz - vFragPos);
					vec3 reflectDir = reflect(-lightDirection, norm);
					float spec = pow(max(dot(viewerDir, reflectDir), 0.0), 32.0);
					vec3 specular = specularStrength * spec * lightColor;

					/* Apply ambient and diffuse lighting */
					vec3 litColor = cColor * (ambientStrength + diffuse + specular);
					
					gl_FragColor = vec4(litColor, 1.0);
				}";

		_glProgram = glCreateProgram(gl, vertexSource, fragmentSource);
		if (_glProgram == null)
		{
			return;
		}

		// Get references to GLSL attributes
		_programVertexAttribute = gl.getAttribLocation(_glProgram, "aPosition");
		gl.enableVertexAttribArray(_programVertexAttribute);

		_programTextureAttribute = gl.getAttribLocation(_glProgram, "aTexCoord");
		gl.enableVertexAttribArray(_programTextureAttribute);

		_programColorAttribute = gl.getAttribLocation(_glProgram, "aColor");
		gl.enableVertexAttribArray(_programColorAttribute);

		_programNormalAttribute = gl.getAttribLocation(_glProgram, "aNormal");
		gl.enableVertexAttribArray(_programNormalAttribute);

		_programMatrixUniform = gl.getUniformLocation(_glProgram, "uMatrix");
		_programModelMatrixUniform = gl.getUniformLocation(_glProgram, "uModel");
		_programImageUniform = gl.getUniformLocation(_glProgram, "uImage0");
		_programLightColorUniform = gl.getUniformLocation(_glProgram, "uLight");
		_programLightPositionUniform = gl.getUniformLocation(_glProgram, "uLightPos");
		_programViewerPositionUniform = gl.getUniformLocation(_glProgram, "uViewerPos");

		trace('Light: aPosition=${_programVertexAttribute}, aTexCoord=${_programTextureAttribute}, aColor=${_programColorAttribute}, uMatrix=${_programMatrixUniform}, uLight=${_programLightColorUniform}');
	}

	public function render(gl:WebGLRenderContext, context:Context3D, projectionMatrix:Matrix3D, lightColor:RGBA, lightPosition:Float32Array,
			cameraPosition:Float32Array):Void
	{
		if (_glProgram == null)
		{
			return;
		}

		gl.useProgram(_glProgram);

		for (c in _cubes)
		{
			// Create model/view/projection matrix from components
			var fullProjection = new Matrix3D();
			fullProjection.identity();
			fullProjection.append(c.modelMatrix);

			// If this is a currently moving cube at the rotation matrix
			if (_affectedCubes.contains(c.id) && _rotMatrix != null)
			{
				fullProjection.append(_rotMatrix);
			}

			// Whole cube model matrix - currently a no-op.
			var modelMatrix = new Matrix3D();
			modelMatrix.append(_cubeRotation);
			fullProjection.append(modelMatrix);

			// Convert matrix to Float32Array and push in shader uniform
			// Pass in model matrix - no projection
			gl.uniformMatrix4fv(_programModelMatrixUniform, false, matrix3DToFloat32Array(fullProjection));

			// Add projection and pass in to shader
			fullProjection.append(projectionMatrix);
			gl.uniformMatrix4fv(_programMatrixUniform, false, matrix3DToFloat32Array(fullProjection));
			gl.uniform1i(_programImageUniform, 0);
			var lightColorArr = new Float32Array([lightColor.r, lightColor.g, lightColor.b]);
			gl.uniform3fv(_programLightColorUniform, lightColorArr, 0);
			gl.uniform3fv(_programLightPositionUniform, lightPosition, 0);
			gl.uniform3fv(_programViewerPositionUniform, cameraPosition, 0);
			gl.bindTexture(gl.TEXTURE_2D, _glTexture);

			// Apply GL calls to submit the cubbe data to the GPU
			// var stride = Float32Array.BYTES_PER_ELEMENT * 12;
			// gl.bindBuffer(gl.ARRAY_BUFFER, c.cube._glVertexBuffer);
			// gl.vertexAttribPointer(_programVertexAttribute, 3, gl.FLOAT, false, stride, 0);
			// gl.vertexAttribPointer(_programTextureAttribute, 2, gl.FLOAT, false, stride, 3 * Float32Array.BYTES_PER_ELEMENT);
			// gl.vertexAttribPointer(_programColorAttribute, 4, gl.FLOAT, false, stride, 5 * Float32Array.BYTES_PER_ELEMENT);
			// gl.vertexAttribPointer(_programNormalAttribute, 3, gl.FLOAT, false, stride, 9 * Float32Array.BYTES_PER_ELEMENT);
			context.setVertexBufferAt(_programVertexAttribute, c.cube._glVertexBuffer, 0, FLOAT_3);
			context.setVertexBufferAt(_programTextureAttribute, c.cube._glVertexBuffer, 3, FLOAT_2);
			context.setVertexBufferAt(_programColorAttribute, c.cube._glVertexBuffer, 5, FLOAT_4);
			context.setVertexBufferAt(_programNormalAttribute, c.cube._glVertexBuffer, 9, FLOAT_3);

			context.drawTriangles(c.cube._glIndexBuffer);
			// gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, c.cube._glIndexBuffer);
			// gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, 0);
		}
	}

	/**
	 * Debug routine to dump the cube position data.
	 * 
	 * @param slice the cube slice to dump.
	 */
	function dumpSlice(slice:Array<CubeData>):Void
	{
		trace('slice:');
		for (c in slice)
		{
			trace('${c.id}:(${c.x}, ${c.y}, ${c.z})');
		}
	}

	/**
	 * Debug routine to dump vertices under the specified transformation
	 *
	 * @param mat the transformation matrix to apply to the points
	 */
	public function dumpTransformVertices(mat:Matrix3D):Void
	{
		// Currently uses a fixed list of interesting points
		for (i => v in [[0.0, 0.0, 0.0], [0.5, 0.5, 0.5]])
		{
			var vector = new Vector3D();
			vector.x = v[0];
			vector.y = v[1];
			vector.z = v[2];
			vector.w = 1;
			var cMat = new Matrix3D();
			cMat.identity();
			if (i > 0)
			{
				cMat.append(createScaleMatrix(SIDE, SIDE, SIDE));
				cMat.append(createTranslationMatrix(START_OFFSET + 2 * SIDE, START_OFFSET + 2 * SIDE, START_OFFSET + 2 * SIDE));
			}
			cMat.append(mat);
			var res = cMat.transformVector(vector);
			trace('v(${v[0]}, ${v[1]}, ${v[2]})=(${res.x}, ${res.y}, ${res.z}, ${res.w})');
		}
	}

	/**
	 * Rotate the Rubik's cube in space.
	 * @param xOffset x axis offset from current value
	 * @param yOffset y axis offset from current value
	 */
	public function rotate(xOffset:Float, yOffset:Float):Void
	{
		var deltaX = xOffset * ROTATION_SENSITIVTY;
		var deltaY = yOffset * ROTATION_SENSITIVTY;

		_yaw += deltaX;
		_pitch += deltaY;

		if (_pitch > 89)
		{
			_pitch = 89;
		}
		if (_pitch < -89)
		{
			_pitch = -89;
		}

		var rotation = new Matrix3D();
		rotation.appendRotation(_yaw, new Vector3D(0, 1, 0));
		rotation.appendRotation(_pitch, new Vector3D(1, 0, 0));
		_cubeRotation = rotation;
	}
}
