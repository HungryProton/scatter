tool
extends "base_modifier.gd"


var Scatter = preload("../core/namespace.gd").new()

export(String, "Node") var node_name
export var radius := 1.0
export var ignore_height := true
export(String, "Curve") var falloff
export var override_global_seed := false
export var custom_seed := 0

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Exclude Around Point"
	category = "Remove"

	if falloff.empty():
		var curve = Curve.new()
		curve.add_point(Vector2(0, 0))
		curve.add_point(Vector2(1, 0))
		curve.bake()
		falloff = Scatter.Util.curve_to_string(curve)


func _process_transforms(transforms, global_seed) -> void:
	if node_name.empty():
		warning += "You must select a node for this modifier to work."
		_notify_warning_changed()
		return

	if not transforms.path.has_node(node_name):
		warning += "Could not find " + node_name + "."
		warning += "\n Make sure the node exists in the scene tree."
		_notify_warning_changed()
		return

	var exclude_root = transforms.path.get_node(node_name)
	var points := _get_exclude_points_recursive(exclude_root)

	var global_transform = transforms.path.global_transform
	var pos: Vector3
	var i := 0

	_rng = RandomNumberGenerator.new()
	if override_global_seed:
		_rng.set_seed(custom_seed)
	else:
		_rng.set_seed(global_seed)

	var curve: Curve = Scatter.Util.string_to_curve(falloff)

	while i < transforms.list.size():
		pos = global_transform.xform(transforms.list[i].origin)
		for p in points:
			var exclude_pos = p.get_global_transform().origin
			if ignore_height:
				pos.y = 0.0
				exclude_pos.y = 0.0

			var distance_to_point := pos.distance_to(exclude_pos)
			var max_distance = (radius * p.radius)

			if distance_to_point < max_distance:
				var falloff_value := curve.interpolate_baked(distance_to_point / max_distance)
				var random_value := _rng.randf()

				if random_value > falloff_value:
					transforms.list.remove(i)
					i -= 1
					break
		i += 1


func _get_exclude_points_recursive(root) -> Array:
	var res = []
	if root is Scatter.ExcludePoint:
		res.push_back(root)

	for child in root.get_children():
		res += _get_exclude_points_recursive(child)

	return res
