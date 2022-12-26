# Asset-Importer-Lib

- [Asset-Importer-Lib](#asset-importer-lib)
  - [Build Steps](#build-steps)
  - [Converting OBJ to GLTF2](#converting-obj-to-gltf2)

These notes are specific to building on Windows, Windows 10 in my case.

Learn OpenGL in part III Model Loading introduces the Asset-Importer-Lib (assimp). Building the assimp library itself is pretty straightforward but if you want to build the tools there are several steps that are required. The main reason for doing this is that there is an asset viewer tool which you can use to get a look at the backpack asset which is used for work in part IV. Further there is assimp_cmd which is a command line convertor. Using this you can convert from one input file type to supported output format. In this case I need to convert the obj to gltf2 for use with Haxe.

Before you build do the following if you wish to build the tools you need to make sure that dependencies required by the viewer are on your system. The view requires DirectX on Windows. In addition there are some configuration changes required.

## Build Steps

Installing the DirectX SDK

   * Install the DirectX SDK, available from https://www.microsoft.com/en-us/download/details.aspx?id=6812

Cloning assimp and running cmake

   * clone the assimp repo per [Build.md](https://github.com/assimp/assimp/blob/master/Build.md).
   * cd assimp
   * edit the CMakeLists.txt
   * Find 

```OPTION( ASSIMP_BUILD_ASSIMP_TOOLS
  "If the supplementary tools for Assimp are built in addition to the library."
  OFF
)
```

and change OFF to ON.

   * cmake CMakeLists.txt
   * You will see an error message concerning DirectX_D3DX9_LIBRARY:
```
-- Configuring done
CMake Error: The following variables are used in this project, but they are set to NOTFOUND.
Please set them or make sure they are set and tested correctly in the CMake files:
DirectX_D3DX9_LIBRARY (ADVANCED)
    linked by target "assimp_viewer" in directory D:/UserData/Daniel/Code/Asset-Importer-Lib/assimp/tools/assimp_view
```
   * Edit CMakeCache.txt and find the reference to
```
   //Path to a library.
DirectX_D3DX9_LIBRARY:FILEPATH=DirectX_D3DX9_LIBRARY-NOTFOUND

```
   * Change the value to the location of the DXSDK d3dx9.lib. You can find this from the system environment variable DXSDK_DIR which is created when you install the SDK. It will be something like this.
```
    DirectX_D3DX9_LIBRARY:FILEPATH=C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)/Lib/x64/d3dx9.lib
```
   * now rerun `cmake CMakeLists.txt`
   This should now correctly build the Visual Studio solution file and the rest of the make support.

Visual Studio

   * Open Visual Studio and load the Assimp.sln solution
   * Before building right click on the assimp_viewer project and go to Properties -> VC++ Directories
      * Modify Include Directories to include $(DXSDK_DIR)Include
      * Modify Library Directories to include $(DXSDK_DIR)Lib\x64 if you are building 64 bit or x86 if 32 bit
   * Now run the build for the Assimp solution

## Converting OBJ to GLTF2

The following command line will convert the backpack.obj to a GLTF2 format file.

```
assimpd.exe export "...\Game Artifacts\Survival Guitar Backpack\backpack.obj" backpack.gltf2 -fgltf2
```

In order to use the gltf2 file you will need to copy over the jpg files - diffuse.jpg, specular.jpg. If you then load this in assimp_viewer you will notice that the opacity texture is not present. It's not in the output JSON (gltf is JSON). But the model loads otherwise. 