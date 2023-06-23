@tool
extends "base_modifier.gd"


@export var position := Vector3.ZERO
@export var rotation := Vector3(0.0, 0.0, 0.0)
@export var scale := Vector3.ONE


func _init() -> void:
	display_name = "Edit Transform"
	category = "Offset"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_local_space_by_default()
	deprecated = true
	deprecation_message = "Use a combination of 'Edit Position', 'Edit Rotation' and 'Edit Scale' instead."

	documentation.add_paragraph(
		"Offsets position, rotation and scale in a single modifier. Every
		transforms generated before will see the same transformation applied.")

	var p := documentation.add_parameter("Position")
	p.set_type("Vector3")
	p.set_description("How far each transforms are moved.")

	p = documentation.add_parameter("Rotation")
	p.set_type("Vector3")
	p.set_description("Rotation angle (in degrees) along each axes (X, Y, Z)")

	p = documentation.add_parameter("Scale")
	p.set_type("Vector3")
	p.set_description("How much to scale the transform along each axes (X, Y, Z)")


func _process_transforms(transforms, domain, _seed) -> void:
	var t: Transform3D
	var local_t: Transform3D
	var basis: Basis
	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.DOWN
	var final_scale := scale
	var final_position := position
	var st: Transform3D = domain.get_global_transform()

	if is_using_local_space():
		axis_x = st.basis.x
		axis_y = st.basis.y
		axis_z = st.basis.z
		final_scale = scale.rotated(Vector3.RIGHT, st.basis.get_euler().x)
		final_position = st.basis * position

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		if is_using_individual_instances_space():
			axis_x = basis.x
			axis_y = basis.y
			axis_z = basis.z
			basis.x *= scale.x
			basis.y *= scale.y
			basis.z *= scale.z
			final_position = t.basis * position

		elif is_using_local_space():
			local_t = t * st
			local_t.basis = local_t.basis.scaled(final_scale)
			basis = (st * local_t).basis

		else:
			basis = basis.scaled(final_scale)

		basis = basis.rotated(axis_x, deg_to_rad(rotation.x))
		basis = basis.rotated(axis_y, deg_to_rad(rotation.y))
		basis = basis.rotated(axis_z, deg_to_rad(rotation.z))
		t.basis = basis
		t.origin += final_position

		transforms.list[i] = t
