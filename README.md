# Scatter
![scatter](https://user-images.githubusercontent.com/52043844/68284290-7ca01780-007d-11ea-979b-128ca7038787.png)

Custom node that takes care to randomly place props or any other scene inside a 3D curve
[See it in action here](https://streamable.com/sms1m)

**Scatter V2 is not backward compatible with the first version**.  
Use the tag selector to go back to older versions if needed.

## Installation
+ Clone this repository in your addons folder
+ Navigate to **Project -> Project Settings -> Plugin** and enable the **Scatter** plugin

## Getting started
Check the two scenes under **addons/scatter/demo** to get an idea of how this addon can be used.

+ Add a **Scatter** node to you scene tree
+ Add a **ScatterItem** node as a child
+ ScatterItem has a **Path Item** parameter. It expect a path to the scene containing the mesh you want to scatter.
+ Use these buttons on top of the viewport to draw a path on your scene. By default, objects will be placed inside the path.
![path_controls](https://user-images.githubusercontent.com/52043844/69886910-b19e3380-12e4-11ea-87ea-39e8d00e2701.png)


## Licence
MIT
