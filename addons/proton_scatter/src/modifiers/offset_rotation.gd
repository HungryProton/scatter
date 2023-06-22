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
	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.FORWARD
	var final_rotation: Vector3

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		match operation:
			0: # Offset
				if is_using_individual_instances_space():
					basis = basis.rotated(basis.x, rotation_rad.x)
					basis = basis.rotated(basis.y, rotation_rad.y)
					basis = basis.rotated(basis.z, rotation_rad.z)

				elif is_using_local_space():
					basis = basis.rotated(Vector3.RIGHT, rotation_rad.x)
					basis = basis.rotated(Vector3.UP, rotation_rad.y)
					basis = basis.rotated(Vector3.FORWARD, rotation_rad.z)

				else:
					basis = basis.rotated(s_gt_inverse.basis * Vector3.RIGHT, rotation_rad.x)
					basis = basis.rotated(s_gt_inverse.basis * Vector3.UP, rotation_rad.y)
					basis = basis.rotated(s_gt_inverse.basis * Vector3.FORWARD, rotation_rad.z)

#				basis = basis.rotated(axis_x, rotation_rad.x)
#				basis = basis.rotated(axis_y, rotation_rad.y)
#				basis = basis.rotated(axis_z, rotation_rad.z)

			1: # Multiply
				pass

			2: # Override
				pass

		transforms.list[i].basis = basis
