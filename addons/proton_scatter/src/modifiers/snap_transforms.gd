@tool
extends "base_modifier.gd"

# TODO: This modifier has the same shortcomings as offset_rotation, but in every reference frame.


@export var position_step := Vector3.ZERO
@export var rotation_step := Vector3.ZERO
@export var scale_step := Vector3.ZERO


func _init() -> void:
	display_name = "Snap Transforms"
	category = "Edit"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_individual_instances_space_by_default()

	documentation.add_paragraph("Snap the individual transforms components.")
	documentation.add_paragraph("Values of 0 do not affect the transforms.")

	var p := documentation.add_parameter("Position")
	p.set_type("Vector3")
	p.set_description("Defines the grid size used to snap the transform position.")

	p = documentation.add_parameter("Rotation")
	p.set_type("Vector3")
	p.set_description(
		"When set to any value above 0, the rotation will be set to the nearest
		multiple of that angle.")
	p.add_warning(
		"Example: If rotation is set to (0, 90.0, 0), the rotation around the Y
		axis will be snapped to the closed value among [0, 90, 180, 360].")

	p = documentation.add_parameter("Scale")
	p.set_type("Vector3")
	p.set_description("Snap the current scale to the nearest multiple.")


func _process_transforms(transforms, domain, _seed) -> void:
	var s_gt: Transform3D = domain.get_global_transform()
	var s_lt: Transform3D = domain.get_local_transform()
	var s_gt_inverse := s_gt.affine_inverse()

	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.FORWARD

	if is_using_global_space():
		axis_x = (s_gt_inverse.basis * Vector3.RIGHT).normalized()
		axis_y = (s_gt_inverse.basis * Vector3.UP).normalized()
		axis_z = (s_gt_inverse.basis * Vector3.FORWARD).normalized()

	var rotation_step_rad := Vector3.ZERO
	rotation_step_rad.x = deg_to_rad(rotation_step.x)
	rotation_step_rad.y = deg_to_rad(rotation_step.y)
	rotation_step_rad.z = deg_to_rad(rotation_step.z)

	for i in transforms.size():
		var t: Transform3D = transforms.list[i]
		var b := Basis()
		var current_rotation: Vector3

		if is_using_individual_instances_space():
			axis_x = t.basis.x.normalized()
			axis_y = t.basis.y.normalized()
			axis_z = t.basis.z.normalized()

			current_rotation = t.basis.get_euler()
			t.origin = snapped(t.origin, position_step)

		elif is_using_local_space():
			var local_t := s_lt * t
			current_rotation = local_t.basis.get_euler()
			t.origin = snapped(t.origin, position_step)

		else:
			b = (s_gt_inverse * Transform3D()).basis
			var global_t := s_gt * t
			current_rotation = global_t.basis.get_euler()
			t.origin = s_gt_inverse * snapped(global_t.origin, position_step)

		b = b.rotated(axis_x, snapped(current_rotation.x, rotation_step_rad.x))
		b = b.rotated(axis_y, snapped(current_rotation.y, rotation_step_rad.y))
		b = b.rotated(axis_z, snapped(current_rotation.z, rotation_step_rad.z))

		# Snap scale
		var current_scale := t.basis.get_scale()
		var snapped_scale: Vector3 = snapped(current_scale, scale_step)
		t.basis = b
		transforms.list[i] = t.scaled_local(snapped_scale)


func _clamp_vector(vec3, vmin, vmax) -> Vector3:
	vec3.x = clamp(vec3.x, vmin.x, vmax.x)
	vec3.y = clamp(vec3.y, vmin.y, vmax.y)
	vec3.z = clamp(vec3.z, vmin.z, vmax.z)
	return vec3
