tool
extends "base_modifier.gd"


export(float) var x_spacing = 1.0
export(float) var z_spacing = 1.0


func _init() -> void:
	display_name = "Distribute Inside (Grid)"
	warning_ignore_no_transforms = true


func _process_transforms(transforms, random_seed) -> void:
	x_spacing = max(0.05, x_spacing)
	z_spacing = max(0.05, z_spacing)
	
	var center = transforms.path.center
	var size = transforms.path.size
	var half_size = size * 0.5
	var height: float = transforms.path.bounds_max.y
	
	var width: int = ceil(size.x / x_spacing)
	var length: int = ceil(size.z / z_spacing)
	var max_count: int = width * length
	transforms.resize(max_count)
	
	var t_index := 0
	for i in max_count:
		var pos = Vector3.ZERO
		pos.x = (i % width) * x_spacing
		pos.z = (i / width) * z_spacing
		pos += (center - half_size)
		pos.y = height

		if transforms.path.is_point_inside(pos):
			transforms.list[t_index].origin = pos
			t_index += 1
	
	if t_index < max_count:
		transforms.remove(max_count - t_index)
