/**
 * MatrixUtils provides a collection of matrix helper functions.
 */

package;

import lime.utils.Float32Array;
import openfl.Vector;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * Create a scaling matrix to scale by the specified amount in each direction.
 * 
 * @param scaleX scale factor in x dimension
 * @param scaleY scale factor in y dimension
 * @param scaleZ scale factor in z dimension
 * @return Matrix3D
 */
function createScaleMatrix(scaleX:Float, scaleY:Float, scaleZ:Float):Matrix3D
{
	var scaleMatrix = new Matrix3D();
	scaleMatrix.appendScale(scaleX, scaleY, scaleZ);
	return scaleMatrix;
}

/**
 * Create a translation matrix to translate to the specified coordinates.
 * 
 * @param x translation in x direction
 * @param y translation in y direction
 * @param z translation in z direction
 * @return Matrix3D
 */
function createTranslationMatrix(transX:Float, transY:Float, transZ:Float):Matrix3D
{
	var translationMatrix = new Matrix3D();
	translationMatrix.appendTranslation(transX, transY, transZ);
	return translationMatrix;
}

/**
 * Create a lookat matrix for a specified camera position, target and up vector.
 *
 * @param cameraPos camera position vector in world coordinates
 * @param target target the camera is "looking at"
 * @param up the camera up vector
 * @return Matrix3D
 */
function createLookAtMatrix(cameraPos:Vector3D, target:Vector3D, up:Vector3D):Matrix3D
{
	var cameraDir = cameraPos.subtract(target);
	cameraDir.normalize();
	var cameraRight = up.crossProduct(cameraDir);
	cameraRight.normalize();
	var cameraUp = cameraDir.crossProduct(cameraRight);
	var cameraMat = new Matrix3D();

	cameraMat.copyRawDataFrom(Vector.ofArray([
		cameraRight.x, cameraUp.x, cameraDir.x, 0,
		cameraRight.y, cameraUp.y, cameraDir.y, 0,
		cameraRight.z, cameraUp.z, cameraDir.z, 0,
		            0,          0,           0, 1
	]));
	var cameraPosMat = new Matrix3D();
	cameraPosMat.copyRawDataFrom(Vector.ofArray([
		           1,            0,            0, 0,
		           0,            1,            0, 0,
		           0,            0,            1, 0,
		-cameraPos.x, -cameraPos.y, -cameraPos.z, 1
	]));
	cameraPosMat.append(cameraMat); // This is the LookAt matrix

	return cameraPosMat;
}

/**
 * Create an orthographic projection matrix for the specified frustum
 * 
 * @param left left extent of the near plane of the frustum
 * @param right right extent of the near plane of the frustum
 * @param top top extent of the near plane of the frustum
 * @param bottom bottom extent of the near plane of the frustum
 * @param near distance to the near plane of the frustum
 * @param far distance to the far plane of the frustum
 * @return Matrix3D
 */
function createOrthoProjection(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float):Matrix3D
{
	var rc = new Matrix3D();
	rc.copyRawDataFrom(Vector.ofArray([
		2.0 / (right - left),
		0.0,
		0.0,
		0.0,
		0.0,
		2.0 / (top - bottom),
		0.0,
		0.0,
		0.0,
		0.0,
		-2.0 / (far - near),
		0.0,
		-(right + left) / (right - left),
		-(top + bottom) / (top - bottom),
		-(far + near) / (far - near),
		1.0
	]));
	return rc;
}

/**
 * Create a perspective projection matrix for the specified frustum.
 * Note, for OpenGL near and far are both positive despite all coordinates being on the negative z-axis. This
 * is OpenGL convention.
 * 
 * @param left left extent of the near plane of the frustum
 * @param right right extent of the near plane of the frustum
 * @param top top extent of the near plane of the frustum
 * @param bottom bottom extent of the near plane of the frustum
 * @param near distance to the near plane of the frustum
 * @param far distance to the far plane of the frustum
 * @return Matrix3D
 */
overload extern inline function createPerspectiveProjection(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float):Matrix3D
{
	var rv = new Matrix3D();
	rv.copyRawDataFrom(Vector.ofArray([
		    2.0 * near / (right - left),                             0.0,                            0.0, 0.0,
		                            0.0,     2.0 * near / (top - bottom),                            0.0, 0.0,
		(right + left) / (right - left), (top + bottom) / (top - bottom),   -(far + near) / (far - near),  -1,
		                            0.0,                             0.0, -2 * far * near / (far - near), 0.0
	]));
	return rv;
}

/**
 * Create a perspective projection matrix based on FOV, aspect ratio and near and far planes.
 * @param fov field of view in degrees
 * @param aspectRatio aspect ratio of camera
 * @param zNear distance from camera to near plane
 * @param zFar distance to far plane
 * @return Matrix3D
 */
overload extern inline function createPerspectiveProjection(fov:Float, aspectRatio:Float, zNear:Float, zFar:Float):Matrix3D
{
	var top = Math.tan(radians(fov)) * zNear;
	var bottom = -top;
	var right = top * aspectRatio;
	var left = -right;
	return createPerspectiveProjection(left, right, top, bottom, zNear, zFar);
}

/**
 * Convert an angle in degrees to radians.
 * @param deg degrees to convert
 * @return Float radians value
 */
function radians(deg:Float):Float
{
	return deg * Math.PI / 180;
}

/**
 * Convert an openfl.geom.Matrix3D to a lime.utils.Float32Array
 * @param m Matrix3D to convert
 * @return Float32Array
 */
function matrix3DToFloat32Array(m:Matrix3D):Float32Array
{
	var fPArray = new Array<Float>();
	for (v in m.rawData)
	{
		fPArray.push(v);
	}
	return new Float32Array(fPArray);
}

/**
 * Convert a Vector3D to a Float32Array.
 * @param v the Vector3D to convert
 * @return Float32Array
 */
function vector3DToFloat32Array(v:Vector3D):Float32Array
{
	return new Float32Array([v.x, v.y, v.z, v.w]);
}
