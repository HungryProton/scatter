extends ScatterRender

const ProtonScatterUtil := preload('./../common/scatter_util.gd')
const ProtonScatterTransformList := preload('./../common/transform_list.gd')

func render(scatter: ProtonScatter, 
			item: ProtonScatterItem, 
			root: Node3D, 
			transforms: ProtonScatterTransformList
			):
				
	var transforms_count: int = transforms.size()

	var child_count := root.get_child_count()
	var transforms_list:= transforms.list
	for i: int in transforms.size():
		
		var instance: Node3D 
		
		if  i < child_count:
			# Use existing instance if possible
			instance = root.get_child(i)
		else:
			instance = _create_instance(item, root, scatter.show_output_in_tree)  
		if not instance:
			break

		instance.transform = transforms_list[i]
		ProtonScatterUtil.set_visibility_layers(instance, item.visibility_layers)
		i += 1
	
	# Delete the unused instances left in the pool if any
	if transforms_count < child_count:
		for i in (child_count - transforms_count):
			root.get_child(-1).queue_free()


func _create_instance(item: ProtonScatterItem, root: Node3D, show_output_in_tree: bool):
	if not item:
		return null

	var instance = item.get_item()
	if not instance:
		return null

	instance.visible = true
	root.add_child.bind(instance, true).call_deferred()

	if show_output_in_tree:
		# We have to use a lambda here because ProtonScatterUtil isn't an
		# actual class_name, it's a const, which makes it impossible to reference
		# the callable, (but we can still call it)
		var defer_ownership := func(i, o):
			ProtonScatterUtil.set_owner_recursive(i, o)
		defer_ownership.bind(instance, item.get_tree().get_edited_scene_root()).call_deferred()

	return instance
