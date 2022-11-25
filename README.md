# Virtual Rubiks Cube

The aims of this example are:
   Produce an OpenFL based Rubik's cube simulation
   Experiment with OpenGL in OpenFL working through Learn OpenGL - Graphics Programming by Joey de Vries
   Experiment with 2D and 3D graphics in the one application

The stack used is lime, openfl and haxeui.

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
   * add game controller support
   * add camera movement by controller
   * fix -ve angle rotation operations
   * add cube rotation
      * how does this differ from a flying camera ?
   * refactor and simplify RubiksCube.updateLocations()
   * add error logging handler
   * handle window resize

