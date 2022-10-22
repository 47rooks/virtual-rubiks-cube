/**
 * Camera module.
 */

package;

import MatrixUtils.createLookAtMatrix;
import MatrixUtils.radians;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * Camera movement directions.
 */
enum CameraMovement
{
	FORWARD;
	BACKWARD;
	LEFT;
	RIGHT;
}

/**
 * The Camera class defines a view of the world from a point in the world (the position) and supports
 * moving, looking around and zooming in and out.
 */
class Camera
{
	final LOOK_AROUND_SENSITIVTY = 0.5;
	final MOVE_SPEED = 500;

	// Camera and world vectors
	var _cameraPos:Vector3D;
	var _cameraFront:Vector3D;
	var _cameraRight:Vector3D;
	var _worldUp:Vector3D;

	/**
	 * Field of View, in degrees.
	 */
	public var fov(default, null) = 45.0;

	var _yaw:Float;
	var _pitch:Float;

	/**
	 * Constructor
	 * @param pos position of the camera in world coordinates, as a vector
	 * @param cameraUp the camera up vector
	 * @param yaw the camera yaw angle, in degrees
	 * @param pitch the camera pitch angle, in degrees
	 */
	public function new(pos:Vector3D, cameraUp:Vector3D, yaw:Float = -90.0, pitch:Float = 0.0)
	{
		_cameraPos = pos;
		_worldUp = cameraUp;
		_cameraFront = new Vector3D(0, 0, -1);
		_yaw = yaw;
		_pitch = pitch;
	}

	/**
	 * Get the view matrix for the camera, also known as the lookat matrix.
	 * @return Matrix3D
	 */
	public function getViewMatrix():Matrix3D
	{
		return createLookAtMatrix(_cameraPos, _cameraPos.add(_cameraFront), _worldUp);
	}

	/**
	 * Move the camera about the world.
	 * @param direction the direction of movement
	 * @param deltaTime time since last update, basically inverse of frame rate, to normalize speed
	 */
	public function move(direction:CameraMovement, deltaTime:Float):Void
	{
		var speed = MOVE_SPEED * deltaTime;
		switch (direction)
		{
			case FORWARD:
				var tgt = _cameraFront.clone();
				tgt.scaleBy(speed);
				_cameraPos = _cameraPos.add(tgt);
			case BACKWARD:
				var tgt = _cameraFront.clone();
				tgt.scaleBy(speed);
				_cameraPos = _cameraPos.subtract(tgt);
			case RIGHT:
				var m = _cameraFront.crossProduct(_worldUp);
				m.normalize();
				m.scaleBy(speed);
				_cameraPos = _cameraPos.subtract(m);
			case LEFT:
				var m = _cameraFront.crossProduct(_worldUp);
				m.normalize();
				m.scaleBy(speed);
				_cameraPos = _cameraPos.add(m);
		}
	}

	/**
	 * Adjust the direction the camera is looking.
	 * @param xOffset offset from the current x direction, in arbitrary units
	 * @param yOffset offset from the current y direction, in arbitrary units
	 */
	public function lookAround(xOffset:Float, yOffset:Float):Void
	{
		var deltaX = xOffset * LOOK_AROUND_SENSITIVTY;
		var deltaY = yOffset * LOOK_AROUND_SENSITIVTY;

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

		var direction = new Vector3D();
		direction.x = Math.cos(radians(_yaw)) * Math.cos(radians(_pitch));
		direction.y = Math.sin(radians(_pitch));
		direction.z = Math.sin(radians(_yaw)) * Math.cos(radians(_pitch));
		direction.normalize();
		_cameraFront = direction;
	}

	/**
	 * Zoom the camera in or out, capped to 1.0 -> 45.0 degrees FOV.
	 * @param delta adjustment to the FOV angle, degrees.
	 */
	public function zoom(delta:Float):Void
	{
		fov -= delta;
		if (fov < 1.0)
		{
			fov = 1.0;
		}
		if (fov > 45)
		{
			fov = 45;
		}
	}
}
