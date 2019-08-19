# Fill Area

![fill_addon](https://user-images.githubusercontent.com/52043844/63270110-cad02680-c297-11e9-8154-783eaf4320da.png)

Custom node that takes care to randomly place props or any other scene inside a 3D curve
[See it in action here](https://streamable.com/1kbnz)

## Important
This addon is still a work in progress and is **not** considered production-ready yet. 

## Installation
+ Install the [path addon](https://github.com/HungryProton/gm_path) first and make sure its active
+ Clone this repository in your addon folder.

## How to use
+ Add a GM_FillArea node to your scene. This node defines how many total objects you will get and the shape of the area to fill.
+ Draw a path using the control panel on the top. (Some button icons may be broken at the moment)
+ Add a GM_ItemArea as a child of this node. The GM_ItemArea define which scene should be duplicated. The proportion is used in case you have many ItemArea under the same FillArea.
