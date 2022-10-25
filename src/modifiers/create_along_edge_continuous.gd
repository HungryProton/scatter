@tool
extends "base_modifier.gd"


@export var item_length := 2.0
@export var ignore_slopes := false

var _current_offset = 0.0


func _init() -> void:
	display_name = "Create Along Edge (Continuous)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	use_edge_data = true


func _process_transforms(transforms, domain, _seed) -> void:
	var new_transforms: Array[Transform3D] = []
	var curves: Array[Curve3D] = domain.get_edges()
	for curve in curves:
		if not ignore_slopes:
			curve = curve.duplicate()
		else:
			curve = get_projected_curve(curve)

		curve.bake_interval = item_length
		var points = curve.get_baked_points()
		var count = points.size()

		var p1: Vector3
		var p2: Vector3
		var t: Transform3D

		for i in count - 1:
			p1 = points[i]
			p2 = points[i + 1]
			t = Transform3D()
			t.origin = p1 + ((p2 - p1) / 2.0)
			new_transforms.push_back(t.looking_at(p2, Vector3.UP))

	transforms.append(new_transforms)


func get_projected_curve(curve: Curve3D) -> Curve3D:
	var points = curve.tessellate()
	var new_curve = Curve3D.new()
	for p in points:
		p.y = 0.0
		new_curve.add_point(p)

	return new_curve
