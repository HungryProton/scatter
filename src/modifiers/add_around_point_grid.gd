tool
extends "base_point_modifier.gd"


export var filter_overlaps := false
export var x_spacing := 2.0
export var z_spacing := 2.0


func _init() -> void:
	display_name = "Add Around Point (Grid)"
	category = "Create"
	enabled = true
	warning_ignore_no_transforms = true


func _process_transforms(transforms, global_seed) -> void:
	._process_transforms(transforms, global_seed)

	x_spacing = max(0.05, x_spacing)
	z_spacing = max(0.05, z_spacing)

	var size = bounds_max - bounds_min
	var half_size = size * 0.5
	var center: Vector3 = bounds_min + half_size
	var width := int(ceil(size.x / x_spacing))
	var length := int(ceil(size.z / z_spacing))
	var max_count: int = width * length

	for i in max_count:
		var pos = Vector3.ZERO
		pos.x = (i % width) * x_spacing
		pos.z = (i / width) * z_spacing
		pos += center - half_size

		for p in points:
			if is_inside(pos, p):
				var p_pos = t.xform_inv(p.get_global_transform().origin)
				pos.y = p_pos.y
				var t = Transform()
				t.origin = pos
				transforms.list.push_back(t)
				if filter_overlaps:
					break

	shuffle(transforms.list, global_seed)
