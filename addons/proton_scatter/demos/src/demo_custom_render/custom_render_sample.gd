extends ScatterRender

## Custom render sample

const TransformList := preload("res://addons/proton_scatter/src/common/transform_list.gd")

## scatter:    The ProtonScatter node
##
## config:     The ScatterRenderConfig set on the node.
##             By creating your own resource type; this allows to have custom configuration
##             properties inside of the scatter node inspector panel.
##
## item:      ScatterItem node being rendered
##
## root:      Output node to generate your render items under
##
## mesh_instance: Merged version of meshes found in the item source 
##                (null if wants_item_merged_mesh_instance is overriden to indicate false) 
##
## transforms: The transforms 
##
func render(scatter: ProtonScatter, 
			config: Resource, 
			item: ProtonScatterItem, 
			root: Node3D, 
			mesh_instance: MeshInstance3D, 
			transforms: TransformList
			):

	print("Using sample protonscatter_custom_render")

	if config and config is DemoScatterRenderConfig:
		print(config.greetings)

	# replace this with your render implementation
	# See /render directory for the existing modes for examples

	
