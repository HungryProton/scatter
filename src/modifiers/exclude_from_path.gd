tool
extends Node


export(String) var path_name

var display_name := "Exclude From Path"


func process_transforms(transforms, _seed) -> void:
	if not transforms.path.has_node(path_name):
		return
	
	var exclude_root = transforms.path.get_node(path_name)
	var paths := _get_paths_recursive(exclude_root)
	
	var global_transform = transforms.path.global_transform
	var pos: Vector3
	var i := 0
	while i < transforms.list.size():
		pos = global_transform.xform(transforms.list[i].origin)
		for p in paths:
			if p.is_point_inside(p.global_transform.xform_inv(pos)):
				transforms.list.remove(i)
				i -= 1
				break
		i += 1


func _get_paths_recursive(root) -> Array:
	var res = []
	if root is Path:
		res.push_back(root)
		
	for c in root.get_children():
		if c is Path:
			res += _get_paths_recursive(c)
	
	return res
