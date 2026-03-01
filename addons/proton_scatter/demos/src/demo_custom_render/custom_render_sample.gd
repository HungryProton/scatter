extends ScatterRender

## Custom render sample

## This will be auto-set if present; used here just to pass through to default instancing render
var merged_mesh_instance: MeshInstance3D 


## This will be called, per item
## For each ProtonScatter render (refresh of scattering); a new instance of your renderer will be used.
## It will get N render calls (N = number of items under the ProtonScatter node). 
func render(scatter: ProtonScatter, 
			item: ProtonScatterItem, 
			root: Node3D, 
			transforms: TransformList
			):

	print("Using example custom renderer")
	
	var render_config: DemoScatterRenderConfig = scatter.custom_render_config as DemoScatterRenderConfig 
	print(render_config.greetings)

	var item_config: DemoScatterItemRenderconfig = item.custom_item_render_config as DemoScatterItemRenderconfig 
	print(item_config.example)

	# replace this with your render implementation
	# See /render directory for the existing modes for examples
	
	# Example of pass-through to one of proton's build in render modes
	scatter.default_render(ProtonScatter.RENDER_MODE_INSTANCING, scatter, item, root, transforms, merged_mesh_instance)

	# Just render some extra spheres
	for t: Transform3D in transforms.list:
		var sphere: CSGSphere3D = CSGSphere3D.new()
		sphere.radius = 0.25
		sphere.top_level = true # The transforms are global
		sphere.transform = t

		# Root is where you add whatever nodes (if any) you need to render the item
		root.add_child(sphere)

		# Do this if you want to support baking / showing output in tree of your generated nodes
		if scatter.show_output_in_tree:
			sphere.owner = root.get_tree().edited_scene_root
