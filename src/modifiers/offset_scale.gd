@tool
extends "base_modifier.gd"


@export var scale := Vector3(1, 1, 1)


func _init() -> void:
	display_name = "Offset Scale"
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
	var st: Transform3D = domain.get_global_transform()
	var basis: Basis

	for i in transforms.size():
		basis = transforms.list[i].basis

		if is_using_individual_instances_space():
			basis.x *= scale.x
			basis.y *= scale.y
			basis.z *= scale.z
		elif is_using_local_space():
			basis = basis.scaled(scale) # TODO: same as offset transform
		else:
			basis = basis.scaled(scale)

		transforms.list[i].basis = basis
