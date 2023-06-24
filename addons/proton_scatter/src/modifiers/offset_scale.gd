@tool
extends "base_modifier.gd"


@export_enum("Offset:0", "Multiply:1", "Override:2") var operation: int = 1
@export var scale := Vector3(1, 1, 1)


func _init() -> void:
	display_name = "Edit Scale"
	category = "Offset"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_individual_instances_space_by_default()

	documentation.add_paragraph("Scales every transform.")

	var p := documentation.add_parameter("Scale")
	p.set_type("Vector3")
	p.set_description("How much to scale the transform along each axes (X, Y, Z)")


func _process_transforms(transforms, domain, _seed) -> void:
	var s_gt: Transform3D = domain.get_global_transform()
	var s_lt: Transform3D = domain.get_local_transform()
	var s_gt_inverse := s_gt.affine_inverse()
	var s_lt_inverse := s_lt.affine_inverse()
	var basis: Basis
	var t: Transform3D
	var tmp_t: Transform3D

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		match operation:
			0: # Offset
				if is_using_individual_instances_space():
					var current_scale := basis.get_scale()
					var s = (current_scale + scale) / current_scale
					basis = t.scaled_local(s).basis

				elif is_using_global_space():
					# Convert to global space, scale, convert back to local space
					tmp_t = s_gt * t
					var current_scale: Vector3 = tmp_t.basis.get_scale()
					tmp_t.basis = tmp_t.basis.scaled((current_scale + scale) / current_scale)
					basis = (s_gt_inverse * tmp_t).basis

				else:
					var current_scale: Vector3 = basis.get_scale()
					basis = basis.scaled((current_scale + scale) / current_scale)

			1: # Multiply
				if is_using_individual_instances_space():
					basis = t.scaled_local(scale).basis

				elif is_using_global_space():
					# Convert to global space, scale, convert back to local space
					tmp_t = s_gt * t
					tmp_t = tmp_t.scaled(scale)
					basis = (s_gt_inverse * tmp_t).basis

				else:
					basis = basis.scaled(scale)

			2: # Override
				if is_using_individual_instances_space():
					var t_scale: Vector3 = basis.get_scale()
					t_scale.x = (1.0 / t_scale.x) * scale.x
					t_scale.y = (1.0 / t_scale.y) * scale.y
					t_scale.z = (1.0 / t_scale.z) * scale.z
					basis = t.scaled_local(t_scale).basis

				elif is_using_global_space():
					# Convert to global space, scale, convert back to local space
					tmp_t = t * s_gt
					var t_scale: Vector3 = tmp_t.basis.get_scale()
					t_scale.x = (1.0 / t_scale.x) * scale.x
					t_scale.y = (1.0 / t_scale.y) * scale.y
					t_scale.z = (1.0 / t_scale.z) * scale.z
					tmp_t.basis = tmp_t.basis.scaled(t_scale)
					basis = (s_gt_inverse * tmp_t).basis

				else:
					var t_scale: Vector3 = basis.get_scale()
					t_scale.x = (1.0 / t_scale.x) * scale.x
					t_scale.y = (1.0 / t_scale.y) * scale.y
					t_scale.z = (1.0 / t_scale.z) * scale.z
					basis = basis.scaled(t_scale)

		transforms.list[i].basis = basis
