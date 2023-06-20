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
	var gt_inverse: Transform3D = domain.get_global_transform().affine_inverse()
	var t: Transform3D

	for i in transforms.list.size():
		t = transforms.list[i]

		var value: Vector3

		if is_using_individual_instances_space():
			value = t.basis * position
		elif is_using_global_space():
			value = gt_inverse.basis * position
		else:
			value = position

		match operation:
			0:
				t.origin += value
			1:
				if is_using_global_space():
					t.origin += value
				else:
					t.origin *= value
			2:
				t.origin = value

		transforms.list[i] = t
