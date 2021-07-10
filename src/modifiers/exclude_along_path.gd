tool
extends "base_modifier.gd"


var Scatter = preload("../core/namespace.gd").new()

export(String, "Node") var path_name
export var width := 4.0
export var ignore_height := true
export(String, "Curve") var falloff
export var override_global_seed := false
export var custom_seed := 0

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Remove Along Path"
	category = "Remove"

	if falloff.empty():
		var curve = Curve.new()
		curve.add_point(Vector2(0, 0))
		curve.add_point(Vector2(1, 0))
		curve.bake()
		falloff = Scatter.Util.curve_to_string(curve)


func _process_transforms(transforms, global_seed) -> void:
	if not transforms.path.has_node(path_name):
		warning += "Could not find " + path_name
		warning += "\n Make sure the curve exists as a child of the Scatter node"
		return

	var exclude_root = transforms.path.get_node(path_name)
	var paths := _get_paths_recursive(exclude_root)

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
		for p in paths:
			var distance_to_point: float = p.distance_from_point(p.global_transform.xform_inv(pos), ignore_height)
			var max_distance: float = width / 2.0

			if distance_to_point < max_distance:
				var falloff_value := curve.interpolate_baked(distance_to_point / max_distance)
				var random_value := _rng.randf()

				if random_value > falloff_value:
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
