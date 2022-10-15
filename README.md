# Virtual Rubiks Cube

This is an OpenFL based Rubik's cube simulation. This is mostly an experiment in OpenGL and matrix manipulation for 3D graphics.

# To Do

   * First
     * document code - in progress
     * add CPU processing for matrix operations for debug and printing
     * add bounding box calculations
   * Second
     * check on the y-axis flip issue
        * is this happening here ?
        * it may be only in ortho-projection but not perspective - not sure
   * figure out how apparent zoom works - why does the cube get bigger or smaller
   * how does the perspective transform work
     * is there a -1 -> 1 bounding box involved ?
   * figure out how the camera position should relate to the frustum and projection
   * add game controller support
   * add camera movement by controller
   * fix -ve angle rotation operations
   * add cube rotation
      * how does this differ from a flying camera ?