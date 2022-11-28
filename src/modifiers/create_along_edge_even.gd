@tool
extends "base_modifier.gd"


const Util := preload("../common/util.gd")


# TODO :
# + change alignement parameters to something more usable and intuitive
# + Use the curve up vector, default to local Y+ when not available
@export var spacing := 1.0
@export var offset := 0.0
@export_enum("X", "Y", "Z") var up_axis := 1
@export var align_x := false
@export var align_y := false
@export var align_z := false

var _min_spacing := 0.05


func _init() -> void:
	display_name = "Create Along Edge (Even)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_restrict_height = false
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false
	use_edge_data = true

	var p
	documentation.add_paragraph(
		"Evenly create transforms along the edges of the ScatterShapes")

	p = documentation.add_parameter("Spacing")
	p.set_type("float")
	p.set_description("How much space between the transforms origin")
	p.set_cost(3)
	p.add_warning("The smaller the value, the denser the resulting transforms list.", 1)
	p.add_warning(
		"A value of 0 would result in infinite transforms, so it's capped
		to 0.05 at least.")


func _process_transforms(transforms, domain, _seed) -> void:
	spacing = max(_min_spacing, spacing)

	var up := get_align_up_vector(up_axis)
	var inverse_basis: Basis = domain.get_global_transform().affine_inverse().basis
	var up_local := up * inverse_basis

	var new_transforms: Array[Transform3D] = []
	var curves: Array[Curve3D] = domain.get_edges()

	for curve in curves:
		var length: float = curve.get_baked_length()
		var count := int(round(length / spacing))
		var stepped_length: float = count * spacing

		for i in count:
			var curve_offset = i * spacing + abs(offset)

			while curve_offset > stepped_length: # Loop back to the curve start if offset is too large
				curve_offset -= stepped_length

			var data : Array = Util.get_position_and_normal_at(curve, curve_offset)
			var pos: Vector3 = data[0]
			var normal: Vector3 = data[1]

			if domain.is_point_excluded(pos):
				continue

			var t := Transform3D()
			t.origin = pos
			t = t.looking_at(normal + pos, up)

			var angles := t.basis.get_euler()
			angles.x *= int(align_x)
			angles.y *= int(align_y)
			angles.z *= int(align_y)

			t.basis = t.basis.from_euler(angles)

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
