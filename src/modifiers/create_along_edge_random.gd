@tool
extends "base_modifier.gd"


@export var instance_count := 10
@export var align_to_path := false
@export var align_up_axis := 1
@export var restrict_x := false
@export var restrict_y := false
@export var restrict_z := false

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Create Along Edge (Random)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false


func _process_transforms(transforms, domain, seed) -> void:
	var path = transforms.path
	transforms.resize(instance_count)

	_rng = RandomNumberGenerator.new()
	_rng.set_seed(seed)

	var length: float = path.curve.get_baked_length()
	for i in transforms.list.size():
		var data = path.get_pos_and_normal(_rng.randf() * length)
		var pos: Vector3 = data[0]
		var normal: Vector3 = data[1]
		var t : Transform3D = transforms.list[i]

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
