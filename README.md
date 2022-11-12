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
   * add game controller support
   * add camera movement by controller
   * fix -ve angle rotation operations
   * add cube rotation
      * how does this differ from a flying camera ?
   * refactor and simplify RubiksCube.updateLocations()
   * add error logging handler
   * handle window resize

# Developer Notes

This program uses two graphics context objects, the `stage.context3D`, a Context3D object which is used to render the vertex buffer, uploading textures, and to call drawTriangles() with the index buffer specifying which vertices to draw. The second context is the GL renderer context and this is used to gain more control of the GL rendering. It is used for setting uniforms, and controlling depth testing and all other GL features.

 Both contexts ultimately render through the GL renderer I believe. The reason this is done is that if the GL render context alone is used and you add other `DisplayObjects` to the stage you get access violations from the `stage.context3D`. So in order to use both a 2D sprite layer and a 3D layer you must at least draw through the `Context3D`. I do not know why this works nor why you get access violations if you do not do this.