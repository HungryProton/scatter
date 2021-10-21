tool
extends "base_modifier.gd"


var Scatter = preload("../core/namespace.gd").new()

export(String, "Node") var node_name
export var radius := 1.0


var points := []
var bounds_min: Vector3
var bounds_max: Vector3
var t: Transform


func _init() -> void:
	display_name = "(Virtual) Base Point Modifier"
	enabled = false
	warning_ignore_no_path = true


func is_inside_any(pos: Vector3) -> bool:
	for p in points:
		if is_inside(pos, p):
			return true

	return false


func is_inside(pos: Vector3, p) -> bool:
	var point_pos = t.xform_inv(p.get_global_transform().origin)
	pos.y = 0.0
	point_pos.y = 0.0

	var distance_to_point := pos.distance_to(point_pos)
	var max_distance = (radius * p.radius)

	return distance_to_point <= max_distance


func _process_transforms(transforms, _global_seed) -> void:
	if node_name.empty():
		warning += "You must select a node for this modifier to work."
		_notify_warning_changed()
		return

	if not transforms.path.has_node(node_name):
		warning += "Could not find " + node_name + "."
		warning += "\n Make sure the node exists in the scene tree."
		_notify_warning_changed()
		return

	t = transforms.path.get_transform()
	var points_root = transforms.path.get_node(node_name)
	points = _get_points_recursive(points_root)
	_update_bounds()


func _get_points_recursive(root) -> Array:
	var res = []
	if root is Scatter.Point:
		res.push_back(root)

	for child in root.get_children():
		res += _get_points_recursive(child)

	return res


func _update_bounds() -> void:
	for i in points.size():
		var p = points[i]
		var r = p.radius * radius
		var pos = t.xform_inv(p.get_global_transform().origin)
		var pmin = pos - Vector3(r, 0.0, r)
		var pmax = pos + Vector3(r, 0.0, r)

		if i == 0:
			bounds_min = pmin
			bounds_max = pmax
			continue

		if pmax.x > bounds_max.x:
			bounds_max.x = pmax.x
		if pmin.x < bounds_min.x:
			bounds_min.x = pmin.x
		if pmax.y > bounds_max.y:
			bounds_max.y = pmax.y
		if pmin.y < bounds_min.y:
			bounds_min.y = pmin.y
		if pmax.z > bounds_max.z:
			bounds_max.z = pmax.z
		if pmin.z < bounds_min.z:
			bounds_min.z = pmin.z
