# Virtual Rubiks Cube

The aims of this example are:
   Produce an OpenFL based Rubik's cube simulation
   Experiment with OpenGL in OpenFL working through Learn OpenGL - Graphics Programming by Joey de Vries
   Experiment with 2D and 3D graphics in the one application

The stack used is lime, openfl and haxeui.

# To Do

   * Immediate
     * fix GLTF loader
       * handling of the materials
       * clean up code handling node/mesh recursion
       * comment fully
       * cleanup and/or refactor Mesh/Model to separate GLTF translation layer from generic data layer
     * add loading message as the model load is done - it takes a while
     * add BaseScene function to get scene clear color as black - subclasses to override if they want different colors
  
   * First
     * document code - in progress
     * add CPU processing for matrix operations for debug and printing
     * add bounding box calculations
   * add game controller support
     * very rudimentary and slightly clunky support is in place now
   * add camera movement by controller
   * fix -ve angle rotation operations
   * add cube rotation
      * how does this differ from a flying camera ?
   * refactor and simplify RubiksCube.updateLocations()
   * add error logging handler
   * handle window resize


