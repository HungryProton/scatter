@tool
extends "base_modifier.gd"


@export var position := Vector3.ZERO


func _init() -> void:
	display_name = "Offset Position"
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
	var st: Transform3D = domain.get_global_transform()
	var t: Transform3D

	for i in transforms.list.size():
		t = transforms.list[i]

		if is_using_individual_instances_space():
			t.origin += t.basis * position
		elif is_using_local_space():
			t.origin += st.basis * position
		else:
			t.origin += position

		transforms.list[i] = t
