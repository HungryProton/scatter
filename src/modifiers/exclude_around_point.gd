tool
extends "base_modifier.gd"


export(String, "Node") var node_name
export(float) var radius = 1.0
export(bool) var ignore_height = true

export(float, 0.0, 1.0) var strength = 1.0
export(Curve) var curve : Curve = Curve.new() #as of now there is no default curve editor, so this value cannot be changed
export(int) var random_seed = -283376

var Scatter = preload("../core/namespace.gd").new()


func _init() -> void:
	display_name = "Exclude Around Point"
	category = "Remove"

	#prepares initial curve values
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(1, 1))
	curve.bake()
 

func _process_transforms(transforms, _seed) -> void:
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
	
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	
	while i < transforms.list.size():
		pos = global_transform.xform(transforms.list[i].origin)
		for p in points:
			var exclude_pos = p.get_global_transform().origin
			if ignore_height:
				pos.y = 0.0
				exclude_pos.y = 0.0
			
			var distance_to_point : float = pos.distance_to(exclude_pos)
			
			if distance_to_point < (radius * p.radius):
				#we can apply gradients that are linked to the distance from the path
				var curve_value := curve.interpolate_baked(distance_to_point)
				var random_value := rng.randf()
				
				if curve_value * strength < random_value:
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
