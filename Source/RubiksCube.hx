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
import haxe.ds.Map;
import lime.math.RGBA;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Program3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.utils.Assets;

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
	private var _context:Context3D;
	private var _faceTexture:RectangleTexture;
	private var _program:Program3D;
	private var _programMatrixUniform:Int;
	private var _programTextureAttribute:Int;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;
	private var _programLightColorUniform:Int;

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
	 * @param context the OpenFL Context3D object to render to
	 * @param x x position to place cube at
	 * @param y y position to place cube at
	 * @param z z position to place cube at
	 * @param scene the owning Scene object, for event dispatch
	 */
	public function new(context:Context3D, x:Int, y:Int, z:Int, scene:Scene)
	{
		SIDE = 64; // FIXME this may need to be a constructor parameter
		START_OFFSET = -(ROW_LEN * SIDE) / 2 + SIDE / 2;
		trace('start_offset=${START_OFFSET}, SIDE=${SIDE}');
		_context = context;
		_x = x;
		_y = y;
		_z = z;
		_scene = scene;

		// Load texture
		var faceImageData = Assets.getBitmapData("assets/openfl.png");
		_faceTexture = _context.createRectangleTexture(faceImageData.width, faceImageData.height, BGRA, false);
		_faceTexture.uploadFromBitmapData(faceImageData);

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

		// Create GLSL program object
		createGLSLProgram();
	}

	/**
	 * Create the required number of cubes with correct colors and positioning data.
	 * 
	 * @param context the Context3D object to which this cube will be rendered
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
					// var c = new Cube(cs, _faceTexture, context);
					var c:Cube = new Cube(cs, _faceTexture);
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

	function createGLSLProgram():Void
	{
		var vertexSource = "attribute vec4 aPosition;
        attribute vec2 aTexCoord;
        varying vec2 vTexCoord;
        
        attribute vec4 aColor;
        varying vec4 vColor;

        uniform mat4 uMatrix;
        
        void main(void) {
            
            vTexCoord = aTexCoord;
            vColor = aColor / vec4(0xff);
            gl_Position = uMatrix * aPosition;
            
        }";

		var fragmentSource = #if !desktop "precision mediump float;" + #end

		"varying vec2 vTexCoord;
            varying vec4 vColor;
            uniform sampler2D uImage0;
            // uniform vec4 uLight;
            
            void main(void)
            {
                /* Lighting */
                float ambientStrength = 0.2;
                // vec3 lightColor = uLight.rgb / 0xff;
                // lightColor = vec4(255.0, 255.0, 255.0, 255.0) / 0xff;
                // vec3 ambient =  lightColor.rgb * vec3(ambientStrength);
                vec4 tColor = texture2D(uImage0, vTexCoord);
                vec3 cColor = tColor.rgb * vColor.rgb;
                if (tColor.a == 0.0) {
                    cColor = vColor.rgb;
                }
                // vec3 litColor = cColor * ambient;   // Apply ambient lighting

                gl_FragColor = vec4(cColor, vColor.a);
            }";

		_program = _context.createProgram(GLSL);
		_program.uploadSources(vertexSource, fragmentSource);

		// Get references to GLSL attributes
		_programVertexAttribute = _program.getAttributeIndex("aPosition");
		_programTextureAttribute = _program.getAttributeIndex("aTexCoord");
		_programColorAttribute = _program.getAttributeIndex("aColor");
		_programMatrixUniform = _program.getConstantIndex("uMatrix");
		_programLightColorUniform = _program.getConstantIndex('uLight');

		trace('Light: aPosition=${_programVertexAttribute}, aTexCoord=${_programTextureAttribute}, aColor=${_programColorAttribute}, uMatrix=${_programMatrixUniform}, uLight=${_programLightColorUniform}');
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
	 * Render the Rubik's cube' current state.
	 * 
	 * @param projectionMatrix projection matrix to apply
	 */
	public function render(projectionMatrix:Matrix3D, lightColor:RGBA):Void
	{
		_context.setProgram(_program);
		_context.setTextureAt(0, _faceTexture);
		_context.setSamplerStateAt(0, CLAMP, LINEAR, MIPNONE);

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

			fullProjection.append(projectionMatrix);

			_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _programMatrixUniform, fullProjection, false);
			// _context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _programLightColorUniform,
			// 	new Vector<Float>(4, false, [lightColor.r, lightColor.g, lightColor.b, lightColor.a]), 1);
			// var sVars:Vector<Float> = Vector.ofArray([255.0, 255.0, 255.0, 255.0]);
			// _context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _programLightColorUniform, sVars);
			// var s:ByteArray = ByteArray.fromBytes(Bytes.ofString('FFFFFFFF'));
			// _context.setProgramConstantsFromByteArray(Context3DProgramType.FRAGMENT, _programLightColorUniform, s, 0);
			_context.setVertexBufferAt(_programVertexAttribute, c.cube.bitmapVertexBuffer, 0, FLOAT_3);
			_context.setVertexBufferAt(_programTextureAttribute, c.cube.bitmapVertexBuffer, 3, FLOAT_2);
			_context.setVertexBufferAt(_programColorAttribute, c.cube.bitmapVertexBuffer, 5, FLOAT_4);
			_context.drawTriangles(c.cube.bitmapIndexBuffer);
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
