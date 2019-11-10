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

### Common parameters

**These are subject to changes.** The scale and rotation randomness might move to the ScatterItem node later. If you have any suggestions or feedback on what makes more sense, please open an issue so we can discuss it.

#### For ScatterDuplicates and ScatterMultimesh

+ **Polygon resolution**
  - Inherited from the parent class, **you can ignore it**.
  - To place points inside a curve, it has to be converted to a polygon first. The lower this value the higher the segments in the polygon. You can see the polygon by clicking the "Show polygon" on top of the viewport.
+ **Curve**
  - The curve you draw on space to delimit the multimesh bounds.
  - If you duplicate a ScatterDuplicate or a ScatterMultimesh node, you have to remove this curve and add a new one, otherwise it will be shared across both nodes, same for the child multimeshes.
+ **Amount**
  - The total instance count. This many items will be placed inside the curve.
+ **Distribution**
  - **Not implemented yet**
  - Defines how the instances are placed, wether they should be random, aligned on a grid or on staggered concentric rings.
+ **Custom Seed**
   - The seed used by the distribution.
   - Will probably be move in the distribution object later.
+ **Project on Floor**
  - If on, the instances are projected to the nearest surface aligned to with the grid.
+ **Ray down length**
  - The length of the raycast from the grid plane if Project on Floor is on.
  - If the raycast can't find a surface, the instance Y position default to 0.
+ **Ray up length**
  - Same but upward. 
  - That's only useful if some geometry sticks above the grid plane, like rocks, and you want your items to cover it as well.
  - The raycast is not fired upward, it's rather an offset of the raycast shot downwards.
+ **Rotation randomness**
  - 0 means no rotation at all, all the instances will face the same direction.
  - Each value represents a different axix.
  - The higher the value, the higher the rotation difference on a given axis.
+ **Scale randomness**
  - 0 means each instance have the same default scale a given axis.
  - The higher the value the higher the difference in scale between each instance.
+ **Global Scale**
  - The default scale for each instance.

#### For ScatterItem

+ **Item Path** : The path to the scene you want to scatter.
+ **Proportion** : 
  - This is useful only if multiple ScatterItems are attached to the same node. 
  - It defines how the total amount of instances is shared across all the items. 
  - If two ScatterItems have a proportion of 50, then half the amount of instances will be of Item1 while the other half will be of Item2. 
  - Internally, the total sum of every Proportion is brought back to 100, and each value is treated like a percentage. So if you have 2 ScatterItems, the first one at 100, the second one at 50, when brought back to 100, its the same as if there where at 67 and 33 respectively. So two thirds of the instances will be made of Item1 while the remaining third will be made of Item2.
+ **Scale Modifier** : The global scale defined in the parent will be multiplied by this parameter so you can make it bigger or smaller than the other items.
+ **Ignore Initial Position** : If true, the position defined in the ItemPath source scene will be ignored. Otherwise, a random translation will be applied on top.
+ **Ignore Initial Rotation** : If true, the rotation defined in the ItemPath source scene will be ignored. Otherwise, a random rotation will be applied on top.
+ **Ignore Initial Scale** : If true, the scale defined in the ItemPath source scene will be ignored. Otherwise, a random scale will be applied on top.

### Licence
MIT
