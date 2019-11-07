# Scatter

![scatter](https://user-images.githubusercontent.com/52043844/68284290-7ca01780-007d-11ea-979b-128ca7038787.png)

Custom node that takes care to randomly place props or any other scene inside a 3D curve
[See it in action here](https://streamable.com/sms1m)

## Installation
+ **Mandatory** : Install the
  [PolygonPath](https://github.com/HungryProton/polygon_path) addon and make
  sure it's enabled
+ Clone this repository in your addon folder
+ Navigate to **Project** -> **Project Settings** -> **Plugin** and enable the
  **Scatter** plugin

## How to use

### ScatterMultimesh

**Use this node to render thousands of meshes, like grass.**
This node make using multimeshes easier but all the intances are simply meshes.
Any scripts attached to it will be ignored.

+ Add a **ScatterMultimesh** node to your tree
+ Draw the area you want to fill with the buttons on top of the viewport
+ Add a **ScatterItem** as a child of your **ScatterMultimesh** node
+ In the **ScatterItem**, under the Select the **Item Path** parameter, select
  the scene containing the mesh you want to scatter

### ScatterDuplicates

**Use this node to scatter dozens of full scenes instances that appears in
your scene tree**
This node actually instance and add the scene to the editor tree so do not use
it to make something like grass (use a **ScatterMultimesh** instead)

+ Add a **ScatterDuplicates** node to your tree
+ Draw the area you want to fill with the buttons on top of the viewport
+ Add a **ScatterItem** as a child of your **ScatterDuplicates** node
+ In the **ScatterItem**, under the Select the **Item Path** parameter, select
  the scene you want to scatter

### Licence
MIT
