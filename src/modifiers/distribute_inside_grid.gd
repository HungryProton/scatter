tool
extends Node


export(float) var x_spacing = 1.0
export(float) var z_spacing = 1.0

var display_name := "Distribute Inside (Grid)"


func process_transforms(transforms, random_seed) -> void:
	x_spacing = max(0.05, x_spacing)
	z_spacing = max(0.05, z_spacing)
	
	var center = transforms.path.center
	var size = transforms.path.size
	var half_size = size * 0.5
	
	var width: int = ceil(size.x / x_spacing)
	var length: int = ceil(size.z / z_spacing)
	var max_count: int = width * length
	transforms.resize(max_count)
	
	var t_index := 0
	for i in max_count:
		var pos = Vector3.ZERO
		pos.x = (i % width) * x_spacing
		pos.y = 0.0
		pos.z = (i / width) * z_spacing
		#print(pos)
		
		pos += (center - half_size)

		if transforms.path.is_point_inside(pos):
			transforms.list[t_index].origin = pos
			t_index += 1
	
	if t_index < max_count:
		transforms.remove(max_count - t_index)
