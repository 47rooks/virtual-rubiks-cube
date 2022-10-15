package;

import MatrixUtils.createTranslationMatrix;
import MatrixUtils.createScaleMatrix;
import openfl.geom.Matrix;
import openfl.events.Event;
import openfl.display3D.Program3D;
import haxe.ds.Map;
import openfl.geom.Vector3D;
import openfl.display3D.Context3DProgramType;
import openfl.geom.Matrix3D;
import openfl.display3D.Context3D;
import openfl.display3D.textures.RectangleTexture;
import lime.math.RGBA;
import Cube.ColorSpec;
import openfl.utils.Assets;

typedef CubeDataPos =
{
	var id:String;
	var x:Int;
	var y:Int;
	var z:Int;
}

typedef CubeData =
{
	var id:String;
	var x:Int;
	var y:Int;
	var z:Int;
	var cube:Cube;
	var scaleMatrix:Matrix3D;
	var rotationMatrix:Matrix3D;
	var translationMatrix:Matrix3D;
	var modelMatrix:Matrix3D;
}

enum abstract Axis(Int)
{
	var X = 0;
	var Y = 1;
	var Z = 2;
	static final vectors = [0 => new Vector3D(1, 0, 0), 1 => new Vector3D(0, 1, 0), 2 => new Vector3D(0, 0, 1)];

	@:to
	public function toVector()
	{
		return vectors[this];
	}
}

enum Operation
{
	RotateSlice(axis:Axis, ordinal:Int, angle:Float);
}

class RubiksCube
{
	static final RED:RGBA = 0xff0000ff;
	static final GREEN:RGBA = 0x00ff00ff;
	static final BLUE:RGBA = 0x0000ffff;
	static final ORANGE:RGBA = 0xF59B42FF;
	static final YELLOW:RGBA = 0xFFFF00ff;
	static final WHITE:RGBA = 0xffffffff;

	final ROW_LEN = 3;
	final SIDE:Float;
	final START_OFFSET:Float;

	// GL interface variables
	private var _context:Context3D;
	private var _faceTexture:RectangleTexture;
	private var _program:Program3D;
	private var _programMatrixUniform:Int;
	private var _programTextureAttribute:Int;
	private var _programVertexAttribute:Int;
	private var _programColorAttribute:Int;

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

	// Scene reference
	var _scene:Scene;

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

		_cubes = new Map<String, CubeData>();
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
					var cs:ColorSpec = {
						front: RED,
						back: ORANGE,
						top: WHITE,
						bottom: YELLOW,
						left: GREEN,
						right: BLUE
					};
					var c = new Cube(cs, _faceTexture, context);
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
					_cubes[cd.id] = cd;
				}
			}
		}

		// Initialize operation data
		_operation = null;
		_incAngle = 0;
		_accAngle = 0;
		_inProgress = false;
		_affectedCubes = new Array<String>();

		// Create GLSL program object
		createGLSLProgram();
	}

	// function createScaleMatrix(scaleX:Float, scaleY:Float, scaleZ:Float):Matrix3D {
	//     var scaleMatrix = new Matrix3D();
	//     scaleMatrix.appendScale(scaleX, scaleY, scaleZ);
	//     return scaleMatrix;
	// }
	// function createTranslationMatrix(transX:Float, transY:Float, transZ:Float):Matrix3D {
	//     var translationMatrix = new Matrix3D();
	//     translationMatrix.appendTranslation(transX, transY, transZ);
	//     return translationMatrix;
	// }

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
            
            void main(void)
            {
                vec4 tColor = texture2D(uImage0, vTexCoord);
                vec3 cColor = tColor.rgb * vColor.rgb;
                if (tColor.a == 0) {
                    cColor = vColor.rgb;
                }
                gl_FragColor = vec4(cColor, vColor.a);
            }";

		_program = _context.createProgram(GLSL);
		_program.uploadSources(vertexSource, fragmentSource);

		// Get references to GLSL attributes
		_programVertexAttribute = _program.getAttributeIndex("aPosition");
		_programTextureAttribute = _program.getAttributeIndex("aTexCoord");
		_programColorAttribute = _program.getAttributeIndex("aColor");
		_programMatrixUniform = _program.getConstantIndex("uMatrix");
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
						updateLocations(angle, axis);

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

	function updateLocations(angle:Float, axis:Axis):Void
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

	function dumpSlice(slice:Array<CubeData>):Void
	{
		trace('slice:');
		for (c in slice)
		{
			trace('${c.id}:(${c.x}, ${c.y}, ${c.z})');
		}
	}

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

	// public function render(projectionMatrix:Matrix3D, programMatrixUniform, programVertexAttribute, programTextureAttribute, programColorAttribute):Void {
	public function render(projectionMatrix:Matrix3D):Void
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

			// Whole cube model matrix
			// This should be rendered by the scene
			// FIXME - create a scene object
			var modelMatrix = new Matrix3D();
			// modelMatrix.appendRotation(35, new Vector3D(1,0,0));
			// modelMatrix.appendRotation(35, new Vector3D(0,1,0));
			// modelMatrix.appendRotation(35, new Vector3D(0,0,1));
			// modelMatrix.appendTranslation(_x, _y, _z);
			fullProjection.append(modelMatrix);

			fullProjection.append(projectionMatrix);

			_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _programMatrixUniform, fullProjection, false);
			_context.setVertexBufferAt(_programVertexAttribute, c.cube.bitmapVertexBuffer, 0, FLOAT_3);
			_context.setVertexBufferAt(_programTextureAttribute, c.cube.bitmapVertexBuffer, 3, FLOAT_2);
			_context.setVertexBufferAt(_programColorAttribute, c.cube.bitmapVertexBuffer, 5, FLOAT_4);
			_context.drawTriangles(c.cube.bitmapIndexBuffer);
		}
	}

	public function dumpTransformVertices(mat:Matrix3D):Void
	{
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
}
