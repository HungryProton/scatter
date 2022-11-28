@tool
extends "base_modifier.gd"


@export var rotation := Vector3.ZERO


func _init() -> void:
	display_name = "Offset Rotation"
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

	var t: Transform3D
	var basis: Basis
	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.FORWARD

	if is_using_local_space():
		var st: Transform3D = domain.get_global_transform()
		axis_x = st.basis.x
		axis_y = st.basis.y
		axis_z = st.basis.z

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		if is_using_individual_instances_space():
			axis_x = basis.x
			axis_y = basis.y
			axis_z = basis.z

		basis = basis.rotated(axis_x, rotation_rad.x)
		basis = basis.rotated(axis_y, rotation_rad.y)
		basis = basis.rotated(axis_z, rotation_rad.z)

		transforms.list[i].basis = basis
