@tool
extends "base_modifier.gd"


@export_enum("Offset:0", "Multiply:1", "Override:2") var operation: int
@export var rotation := Vector3.ZERO


func _init() -> void:
	display_name = "Edit Rotation"
	category = "Offset"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_individual_instances_space_by_default()

	documentation.add_paragraph("Rotates every transform.")

	documentation.add_parameter("Rotation").set_type("Vector3").set_description(
		"Rotation angle (in degrees) along each axes (X, Y, Z)")


func _process_transforms(transforms, domain, _seed : int) -> void:
	var rotation_rad := Vector3.ZERO
	rotation_rad.x = deg_to_rad(rotation.x)
	rotation_rad.y = deg_to_rad(rotation.y)
	rotation_rad.z = deg_to_rad(rotation.z)

	var s_gt: Transform3D = domain.get_global_transform()
	var s_lt: Transform3D = domain.get_local_transform()
	var s_gt_inverse := s_gt.affine_inverse()
	var t: Transform3D
	var basis: Basis
	var axis_x: Vector3
	var axis_y: Vector3
	var axis_z: Vector3
	var final_rotation: Vector3

	if is_using_local_space():
		axis_x = Vector3.RIGHT
		axis_y = Vector3.UP
		axis_z = Vector3.FORWARD

	elif is_using_global_space():
		axis_x = (s_gt_inverse.basis * Vector3.RIGHT).normalized()
		axis_y = (s_gt_inverse.basis * Vector3.UP).normalized()
		axis_z = (s_gt_inverse.basis * Vector3.FORWARD).normalized()

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		match operation:
			0: # Offset
				final_rotation = rotation_rad

			1: # Multiply
				# TMP: Local and global space calculations are probably wrong
				var current_rotation: Vector3

				if is_using_individual_instances_space():
					current_rotation = basis.get_euler()

				elif is_using_local_space():
					var local_t := t * s_lt
					current_rotation = local_t.basis.get_euler()

				else:
					var global_t := t * s_gt
					current_rotation = global_t.basis.get_euler()

				final_rotation = (current_rotation * rotation) - current_rotation

			2: # Override
				# Creates a new basis with the original scale only
				# Applies new rotation on top

				if is_using_individual_instances_space():
					basis = Basis().from_scale(t.basis.get_scale())

				elif is_using_local_space():
					basis = (s_gt_inverse * s_gt).basis

				else:
					var tmp_t = Transform3D(Basis.from_scale(t.basis.get_scale()), Vector3.ZERO)
					basis = (s_gt_inverse * tmp_t).basis

				final_rotation = rotation_rad

		if is_using_individual_instances_space():
			axis_x = basis.x.normalized()
			axis_y = basis.y.normalized()
			axis_z = basis.z.normalized()

		basis = basis.rotated(axis_y, final_rotation.y)
		basis = basis.rotated(axis_x, final_rotation.x)
		basis = basis.rotated(axis_z, final_rotation.z)

		transforms.list[i].basis = basis
