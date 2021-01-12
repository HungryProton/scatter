tool
extends "base_modifier.gd"


export(float) var interval = 1.0
export(float, 0, 100) var offset = 0.0
export(bool) var align_to_path = false
export(int) var align_up_axis = 0
export(bool) var restrict_x = false
export(bool) var restrict_y = false
export(bool) var restrict_z = false

func _init() -> void:
	display_name = "Distribute Along Path (Even)"
	warning_ignore_no_transforms = true


func _process_transforms(transforms, _seed) -> void:
	var path = transforms.path
	var length: float = path.curve.get_baked_length()
	var total_count: int = round(length / interval)# + int(fmod(length, interval) <= interval / 2)
	
	
	if total_count == 0:
		warning += """
		The interval is larger than the curve length.
		No transforms could be placed."""
		return
	
	
	transforms.resize(total_count)
	for i in transforms.list.size():
		var data : Array = path.get_pos_and_normal(fmod(i * interval + abs(offset), length - fmod(length, interval)))
		var pos: Vector3 = data[0]
		var normal: Vector3 = data[1]
		var t : Transform = transforms.list[i]
		
		t.origin = pos
		
		if align_to_path:
			#axis restrictions
			normal.x *= int(!restrict_x)
			normal.y *= int(!restrict_y)
			normal.z *= int(!restrict_z)
			#this does not like restricting both x and z simulatneously
			
			t = t.looking_at(normal + pos, get_align_up_vector(align_up_axis))
		
		transforms.list[i] = t

static func get_align_up_vector(align : int) -> Vector3:
	var axis : Vector3
	match align:
		#x
		0:
			axis = Vector3.RIGHT
		#y
		1:
			axis = Vector3.UP
		#z
		2:
			axis = Vector3.BACK
		_:
			#default return y axis
			axis = Vector3.UP
	
	return axis
