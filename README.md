# Virtual Rubiks Cube

The aims of this example are:
   Produce an OpenFL based Rubik's cube simulation
   Experiment with OpenGL in OpenFL working through Learn OpenGL - Graphics Programming by Joey de Vries
   Experiment with 2D and 3D graphics in the one application

The stack used is lime, openfl and haxeui.

# To Do

   * Immediate
     * create a second Scene for the model loading demo
     * create base scene class and extend it in both scenes
     * fix UI to add reference library info for the model loading case
     * fix mouse targetting code, simplify to target just the model whatever it is, or the camera
     * fix GLTF loader
       * handling of the materials
       * clean up code handling node/mesh recursion
       * comment fully
       * cleanup and/or refactor Mesh/Model to separate GLTF translation layer from generic data layer
     * move light position for the first point light - it obstructs the backpack model
     * add UI label indicating the target of the mouse ?
  
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


