# Scatter
![scatter](https://user-images.githubusercontent.com/52043844/103457605-08084d80-4d01-11eb-98a3-3cdb523d5410.png)  
Custom node for the Godot game engine to randomly place props or scenes using 3D curves. [See it in action here](https://twitter.com/HungryProton/status/1344623041620402176)

**Scatter V2 is not backward compatible with the first version**.  
Use the tag selector to go back to older versions if needed.

## How to use it

### Check out the demos!
Two examples scenes are located in `res://addons/scatter/demos/`, make sure to check them both. This way you'll see how
you can setup your scenes and how this addon can be used.  
![image](https://user-images.githubusercontent.com/52043844/103458397-d5158800-4d07-11eb-8e87-4a81d754c2ef.png)

### Installation guide
+ Make sure you're using **Godot 3.3**
  - This add-on is not compatible with 4.0 yet
  - Older 3.x versions may or may not be compatible  
+ [This project's wiki pages](https://github.com/HungryProton/scatter/wiki) has all the information you should know
in order to use this plugin.
+ [Installation and basic setup](https://github.com/HungryProton/scatter/wiki/Installation-and-basic-setup)
+ [Modifiers](https://github.com/HungryProton/scatter/wiki/Modifiers)
+ [Using presets](https://github.com/HungryProton/scatter/wiki/Using-presets)

## Troubleshooting

### I can't open the demo scenes
Make sure the folder is named `scatter` exactly, nothing else. If you downloaded the archive from GitHub,
if probably renamed that into *scatter-master* or something else, this will break the import / scene paths.
+ Disable the plugin first.
+ Rename the folder into `scatter`.
+ Close the editor and open it again.
  - If you don't Godot will probably complain about cyclic dependencies or something else.
+ Enable the plugin and it should work.

### My collisions are ignored
By default, instancing or batching is enabled (through a MultimeshInstance node) and doesn't support collisions. However
you can turn off instancing in the Scatter node and it will copy the entire source, including colliders, scripts and others.  
![image](https://user-images.githubusercontent.com/52043844/110603386-3eda6400-8187-11eb-84d7-e8ec3fc15e4c.png)

### The addon is slow when editing a curve
When updating a `Scatter Path` object, a 2D polygon projected on the XZ plane is also generated internally.
This polygon is used to know if a point is inside the curve or not. If this polygon resolution is too high, regenerating
it will take time. To fix this, increase the `Bake Interval` on the Scatter node itself. (Not on the curve resource, this one
is not used). Values around 1 or 2 are usually enough, but if your path is really large, you don't need that much precision and
you can increase this value. However, if your path is really small, you can decrease this value.

### The 3D curves are modified at different places at once
[Please read this page](https://github.com/HungryProton/scatter/wiki/Warning-about-duplicating-nodes).
When you duplicate a `Scatter` node, the curve resource is duplicated automatically so this shoudn't happen.
If it does, click on the `Curve3D` resource and click on `Make Unique`. 

### Project on floor ignores my colliders
There is [a known bug in Godot](https://github.com/godotengine/godot/issues/43744) when raycasting from a tool script.
After moving your colliders, the physic world is not synced with their new position, so you have to hit
the `Rebuild` button in the inspector, under the modifier stack. Hit it once after you made modifications to your
scene.


## Don't forget the wiki
If you can't find what you're looking for in this readme, please [check this project wiki](https://github.com/HungryProton/scatter/wiki).
If you're facing a bug, please [check the issues's tracker](https://github.com/HungryProton/scatter/issues) to see if someone else
already reported the issue. If not, feel free to open a new one.


## Licence
- This addon is published under the MIT licence.
- Most 2D and 3D assets in the demos folder are MIT, with a few exceptions. 
Refer the the LICENCE.md in the assets folder for more details.
