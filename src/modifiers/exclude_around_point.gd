tool
extends "base_modifier.gd"


export(String) var node_name
export(float) var radius = 4.0
export(bool) var ignore_height = true


func _init() -> void:
	display_name = "Exclude Around Point"


func _process_transforms(transforms, _seed) -> void:
	if not transforms.path.has_node(node_name):
		warning += "Could not find " + node_name
		warning += "\n Make sure the node exists as a child of the Scatter node"
		_notify_warning_changed()
		return
	
	var exclude_root = transforms.path.get_node(node_name)
	var points := _get_children_recursive(exclude_root)
	
	var global_transform = transforms.path.global_transform
	var pos: Vector3
	var i := 0
	while i < transforms.list.size():
		pos = global_transform.xform(transforms.list[i].origin)
		for p in points:
			var exclude_pos = p.get_global_transform().origin
			if ignore_height:
				pos.y = 0.0
				exclude_pos.y = 0.0
			if pos.distance_to(exclude_pos) < radius:
				transforms.list.remove(i)
				i -= 1
				break
		i += 1


func _get_children_recursive(root) -> Array:
	var res = []
	if root is Spatial:
		res.push_back(root)
		
	for c in root.get_children():
		if c is Spatial:
			res += _get_children_recursive(c)
	
	return res
