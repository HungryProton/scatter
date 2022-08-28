tool
extends "base_modifier.gd"


export var item_length := 2.0
export var ignore_slopes := false

var _current_offset = 0.0


func _init() -> void:
	display_name = "Distribute Along Path (Continuous)"
	category = "Distribute"
	warning_ignore_no_transforms = true
	warning_ignore_no_path = false


func _process_transforms(transforms, _seed) -> void:
	var path: Path = transforms.path
	var curve: Curve3D
	if not ignore_slopes:
		curve = path.curve.duplicate()
	else:
		curve = get_projected_curve(path.curve)

	curve.bake_interval = item_length
	var points = curve.get_baked_points()
	var count = points.size()

	# Last segment will always have the wrong size. so we ignore it.
	transforms.resize(count - 2)
	var p1: Vector3
	var p2: Vector3
	var t: Transform

	for i in transforms.list.size():
		p1 = points[i]
		p2 = points[i + 1]
		t = transforms.list[i]
		t.origin = p1 + ((p2 - p1) / 2.0)
		transforms.list[i] = t.looking_at(p2, Vector3.UP)
	
	shuffle(transforms.list, _seed)


func get_projected_curve(curve: Curve3D) -> Curve3D:
	var points = curve.tessellate()
	var new_curve = Curve3D.new()
	for p in points:
		p.y = 0.0
		new_curve.add_point(p)

	return new_curve
