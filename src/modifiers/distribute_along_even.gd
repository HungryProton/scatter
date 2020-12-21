tool
extends Node


export(float) var interval = 1.0
export(bool) var align_to_path = false

var display_name := "Distribute Along Path (Even)"


func process_transforms(transforms, _seed) -> void:
	var path = transforms.path
	var length: float = path.curve.get_baked_length()
	var total_count: int = round(length / interval)
	transforms.resize(total_count)
	for i in transforms.list.size():
		var data = path.get_pos_and_normal(i * interval)
		var pos: Vector3 = data[0]
		var normal: Vector3 = data[1]
		var t : Transform = transforms.list[i]
		
		if align_to_path:
			t = t.rotated(Vector3.UP, atan2(normal.x, normal.z))
		
		t.origin = pos
		transforms.list[i] = t
