extends ScatterRender

## Custom render sample
## 1. Open the demo scene, select a Scatter node
## 2. Select this script as 'Custom Render Script'
## 3. Select Render Mode 'Custom'
## 
## Note that if you do 3. before 2. youll see a error indicating a script is required.


## scatter:    The scatter node; note using this introduces higher chance if incompatibility
##             of your script with future versions of ProtonScatter
##
## config:     The custom render resource set on the node, cast this to what you expect (if any)
##             By creating your own resource type; this allows to have custom configuration
##             properties inside of the scatter node inspector panel.
##
## items:      [ 
##					{ 
##						"item" : ProtonScatterItem, 
##                 		"mesh": Mesh,
##                 		"root": Node3D 
##                 		"transforms": Array[Transform3d] 
##					}, ... 
##				]
##
## Note that item.process_transform already has been applied to the transforms
func render(scatter: ProtonScatter, 
			config: Resource, 
			item: ProtonScatterItem, 
			root: Node3D, 
			mesh_instance: MeshInstance3D, 
			transforms: Array[Transform3D]
			):

	print("Using sample protonscatter_custom_render")

	if config and config is DemoScatterRenderConfig:
		print(config.greetings)

	# replace this with your render implementation
	# See /render directory for the existing modes for examples

	
