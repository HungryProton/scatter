@tool
extends "base_modifier.gd"


const Util := preload("../common/util.gd")


# TODO :
# + change alignement parameters to something more usable and intuitive
# + Use the curve up vector, default to local Y+ when not available
@export var interval := 1.0
@export var offset := 0.0
@export var align_to_path := false
@export_enum("X", "Y", "Z") var align_up_axis := 1
@export var restrict_x := false
@export var restrict_y := false
@export var restrict_z := false


func _init() -> void:
	display_name = "Create Along Edge (Even)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_restrict_height = false
	can_use_global_and_local_space = false
	use_edge_data = true

	var p
	documentation.add_paragraph(
		"Place transforms along the edges of the ScatterShapes")

	p = documentation.add_parameter("Spacing")
	p.set_type("vector3")
	p.set_description(
		"Defines the grid size along the 3 axes. A spacing of 1 means 1 unit
		of space between each transform on this axis.")
	p.set_cost(3)
	p.add_warning(
		"The smaller the value, the denser the resulting transforms list.
		Use with care as the performance impact will go up quickly.", 1)
	p.add_warning(
		"A value of 0 would result in infinite transforms, so it's capped to 0.05
		at least.")


func _process_transforms(transforms, domain, _seed) -> void:
	var new_transforms: Array[Transform3D] = []
	var curves: Array[Curve3D] = domain.get_edges()
	for curve in curves:
		var length: float = curve.get_baked_length()
		var count := int(round(length / interval))
		var stepped_length: float = count * interval

		for i in count:
			var curve_offset = i * interval + abs(offset)
			while curve_offset > stepped_length:
				curve_offset -= stepped_length

			var data : Array = Util.get_position_and_normal_at(curve, curve_offset)
			var pos: Vector3 = data[0]
			var normal: Vector3 = data[1]
			var up: Vector3 = Vector3.UP * domain.get_global_transform().affine_inverse().basis
			var t := Transform3D()
			t.origin = pos

			if domain.is_point_excluded(pos):
				continue

			if align_to_path: # TODO; change this
				#axis restrictions
				normal.x *= int(!restrict_x)
				normal.y *= int(!restrict_y)
				normal.z *= int(!restrict_z)
				#this does not like restricting both x and z simulatneously

				t = t.looking_at(normal + pos, up)

			new_transforms.push_back(t)

	transforms.append(new_transforms)


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
