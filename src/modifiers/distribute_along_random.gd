tool
extends "base_modifier.gd"


export var override_global_seed := false
export var custom_seed := 0
export var instance_count := 10
export var align_to_path := false
export var align_up_axis := 1
export var restrict_x := false
export var restrict_y := false
export var restrict_z := false

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Distribute Along Path (Random)"
	category = "Distribute"
	warning_ignore_no_transforms = true
	warning_ignore_no_path = false


func _process_transforms(transforms, global_seed) -> void:
	var path = transforms.path
	transforms.resize(instance_count)

	_rng = RandomNumberGenerator.new()
	if override_global_seed:
		_rng.set_seed(custom_seed)
	else:
		_rng.set_seed(global_seed)

	var length: float = path.curve.get_baked_length()
	for i in transforms.list.size():
		var data = path.get_pos_and_normal(_rng.randf() * length)
		var pos: Vector3 = data[0]
		var normal: Vector3 = data[1]
		var t : Transform = transforms.list[i]

		if align_to_path:
			#axis restrictions
			normal.x *= int(!restrict_x)
			normal.y *= int(!restrict_y)
			normal.z *= int(!restrict_z)
			#this does not like restricting both x and z simulatneously

			t = t.looking_at(normal + pos, get_align_up_vector(align_up_axis))

		t.origin = pos
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
