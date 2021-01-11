tool
extends "base_modifier.gd"


export(float) var interval = 1.0
export(float, 0, 100) var offset = 0.0
export(bool) var align_to_path = false
export(int, "X", "Y", "Z") var align_axis = 0
export(int, "X", "Y", "Z") var align_up_axis = 1


func _init() -> void:
	display_name = "Distribute Along Path (Even)"
	warning_ignore_no_transforms = true


func _process_transforms(transforms, _seed) -> void:
	var path = transforms.path
	var length: float = path.curve.get_baked_length()
	var total_count: int = round(length / interval) + int(fmod(length, interval) <= interval / 2)
	
	
	if total_count == 0:
		warning += """
		The interval is larger than the curve length.
		No transforms could be placed."""
		return
	
	
	
	transforms.resize(total_count)
	for i in transforms.list.size():
		var data : Array = path.get_pos_and_normal(fmod(i * interval + abs(offset), length + fmod(length, interval)))
		var pos: Vector3 = data[0]
		var normal: Vector3 = data[1]
		var t : Transform = transforms.list[i]

		if align_to_path:
			if align_axis == align_up_axis:
				warning += """
				The alignment axis is the same as the up axis.
				No alignment has been done.
				"""
#			print(normal)
			t = t.looking_at(normal, get_align_up_vector())
			#after looking at
			
		
		t.origin = pos
		transforms.list[i] = t



func get_align_vector(t : Transform) -> Vector3:
	match align_axis:
		#x
		0:
			return t.basis.y.normalized()
		#y
		1:
			return t.basis.y.normalized()
		#z
		2:
			return t.basis.z.normalized()
		_:
			#default return x axis
			return t.basis.x.normalized()

func get_align_up_vector() -> Vector3:
	match align_up_axis:
		#x
		0:
			return Vector3.RIGHT
		#y
		1:
			return Vector3.UP
		#z
		2:
			return Vector3.BACK
		_:
			#default return y axis
			return Vector3.UP
	
	
