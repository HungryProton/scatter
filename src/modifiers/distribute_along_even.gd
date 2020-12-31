tool
extends "base_modifier.gd"


export(float) var interval = 1.0
export(bool) var align_to_path = false


func _init() -> void:
	display_name = "Distribute Along Path (Even)"
	warning_ignore_no_transforms = true


func _process_transforms(transforms, _seed) -> void:
	var path = transforms.path
	var length: float = path.curve.get_baked_length()
	var total_count: int = round(length / interval)
	
	if total_count == 0:
		warning += """
		The interval is larger than the curve length.
		No transforms could be placed."""
		return
	
	transforms.resize(total_count)

	for i in transforms.list.size():
		var data = path.get_pos_and_normal(i * interval)
		var pos: Vector3 = data[0]
		var normal: Vector3 = data[1]
		var t : Transform = transforms.list[i]
		
		if align_to_path:
			t = t.rotated(t.basis.y.normalized(), atan2(normal.x, normal.z))
			
		t.origin = pos
		transforms.list[i] = t
