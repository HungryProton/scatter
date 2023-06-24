@tool
extends "base_modifier.gd"


@export_enum("Offset:0", "Multiply:1", "Override:2") var operation: int
@export var position := Vector3.ZERO



func _init() -> void:
	display_name = "Edit Position"
	category = "Offset"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_individual_instances_space_by_default()

	documentation.add_paragraph("Moves every transform the same way.")

	var p := documentation.add_parameter("Position")
	p.set_type("vector3")
	p.set_description("How far each transforms are moved.")


func _process_transforms(transforms, domain, _seed) -> void:
	var s_gt: Transform3D = domain.get_global_transform()
	var s_gt_inverse: Transform3D = s_gt.affine_inverse()
	var t: Transform3D

	for i in transforms.list.size():
		t = transforms.list[i]

		var value: Vector3

		if is_using_individual_instances_space():
			value = t.basis * position
		elif is_using_global_space():
			value = s_gt_inverse.basis * position
		else:
			value = position

		match operation:
			0:
				t.origin += value
			1:
				if is_using_local_space():
					t.origin *= value

				if is_using_global_space():
					var global_pos = s_gt * t.origin
					global_pos -= s_gt.origin
					global_pos *= position
					global_pos += s_gt.origin

					t.origin = s_gt_inverse * global_pos

				elif is_using_individual_instances_space():
					pass # Multiply does nothing on this reference frame.
			2:
				t.origin = value

		transforms.list[i] = t
