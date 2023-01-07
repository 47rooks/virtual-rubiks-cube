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
       * it turns out this is a bit tricky the way I planned. I added event sending support at the beginning of scene creation and at the end of the first render. Response to these events would be to disable and then re-enable the UI. This is not quite working. I'll leave it as is for now and revisit it later when perhaps I'll have a better idea how to do this - the main issue is the `pointer-events:none` styling which is not working as expected.
  
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


