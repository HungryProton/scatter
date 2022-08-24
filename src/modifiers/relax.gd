tool
extends "base_modifier.gd"


export var iterations : int = 3
export var offset_step : float = 0.01
export var consecutive_step_multiplier : float = 0.5


func _init() -> void:
	display_name = "Relax Position"
	category = "Edit"


func _process_transforms(transforms, _global_seed) -> void:
	# TODO this can benefit greatly from multithreading
	if transforms.list.size() < 2:
		return
	
	var offset = offset_step
	
	for iteration in iterations:
		for i in transforms.list.size():
			var min_vector = Vector3(99999, 99999, 99999)
			# Find the closest point
			for j in transforms.list.size():
				if i == j:
					continue
				var d = transforms.list[i].origin - transforms.list[j].origin
				if d.length() < min_vector.length():
					min_vector = d
			
			# move away from closest point
			transforms.list[i].origin += min_vector.normalized() * offset
		
		offset *= consecutive_step_multiplier
