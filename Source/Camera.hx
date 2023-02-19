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

enum CameraLookTo
{
	RIGHT;
	LEFT;
	UP;
	DOWN;
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
	public var cameraPos(default, null):Vector3D;

	public var cameraFront(default, null):Vector3D;

	var _cameraRight:Vector3D;
	var _worldUp:Vector3D;

	// Camera speed
	public var move_speed:Float;

	/**
	 * Field of View, in degrees.
	 */
	public var fov(default, null) = 45.0;

	public var yaw:Float;

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
		cameraPos = pos;
		_worldUp = cameraUp;
		cameraFront = new Vector3D(0, 0, -1);
		this.yaw = yaw;
		_pitch = pitch;
		move_speed = MOVE_SPEED;
	}

	/**
	 * Get the view matrix for the camera, also known as the lookat matrix.
	 * @return Matrix3D
	 */
	public function getViewMatrix():Matrix3D
	{
		return createLookAtMatrix(cameraPos, cameraPos.add(cameraFront), _worldUp);
	}

	/**
	 * Move the camera about the world.
	 * @param direction the direction of movement
	 * @param deltaTime time since last update, basically inverse of frame rate, to normalize speed
	 */
	public function move(direction:CameraMovement, deltaTime:Float):Void
	{
		var speed = move_speed * deltaTime;
		switch (direction)
		{
			case FORWARD:
				var tgt = cameraFront.clone();
				tgt.scaleBy(speed);
				cameraPos = cameraPos.add(tgt);
			case BACKWARD:
				var tgt = cameraFront.clone();
				tgt.scaleBy(speed);
				cameraPos = cameraPos.subtract(tgt);
			case RIGHT:
				var m = cameraFront.crossProduct(_worldUp);
				m.normalize();
				m.scaleBy(speed);
				cameraPos = cameraPos.subtract(m);
			case LEFT:
				var m = cameraFront.crossProduct(_worldUp);
				m.normalize();
				m.scaleBy(speed);
				cameraPos = cameraPos.add(m);
		}
	}

	/**
	 * Adjust the direction the camera is looking.
	 * @param xOffset offset from the current x direction, in arbitrary units
	 * @param yOffset offset from the current y direction, in arbitrary units
	 */
	overload extern inline public function lookAround(xOffset:Float, yOffset:Float):Void
	{
		var deltaX = xOffset * LOOK_AROUND_SENSITIVTY;
		var deltaY = yOffset * LOOK_AROUND_SENSITIVTY;

		yaw += deltaX;
		_pitch += deltaY;

		if (_pitch > 89)
		{
			_pitch = 89;
		}
		if (_pitch < -89)
		{
			_pitch = -89;
		}

		calculateFront();
	}

	// FIXME
	// This function is an attempt to get mouse-like function out of the gamepad. It almost works but needs
	// work. Ideally we want something like the Flixel Action support.
	overload extern inline public function lookAround(lookTo:CameraLookTo, delta:Float):Void
	{
		var deltaX = 0.0;
		var deltaY = 0.0;
		switch (lookTo)
		{
			case RIGHT:
				deltaX += delta * 10;
			case LEFT:
				deltaX -= delta * 10;
			case UP:
				deltaY += delta * 10;
			case DOWN:
				deltaY -= delta * 10;
		}

		yaw += deltaX;
		_pitch += deltaY;

		if (_pitch > 89)
		{
			_pitch = 89;
		}
		if (_pitch < -89)
		{
			_pitch = -89;
		}

		calculateFront();
	}

	/**
	 * Update the front matrix.
	 * This should probably be a proper update all matrices and state kind of call, but
	 * in this somewhat hack implementation of a camera this is all that's needed to
	 * be able to look behind, as needed by the framebuffer demo.
	 */
	public function calculateFront():Void
	{
		var direction = new Vector3D();
		direction.x = Math.cos(radians(yaw)) * Math.cos(radians(_pitch));
		direction.y = Math.sin(radians(_pitch));
		direction.z = Math.sin(radians(yaw)) * Math.cos(radians(_pitch));
		direction.normalize();
		cameraFront = direction;
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
