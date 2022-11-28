@tool
extends "base_modifier.gd"


@export var exclusive_shapes_only := false


func _init() -> void:
	display_name = "Remove Outside"
	category = "Remove"
	can_restrict_height = false
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false

	documentation.add_paragraph(
		"Remove all transforms falling outside a ScatterShape node, or inside
		a shape set to 'Exclusive' mode.")

	var p := documentation.add_parameter("Exclusive Shapes Only")
	p.set_type("bool")
	p.set_description(
		"Only remove transforms falling inside the exclusive shapes (shown
		in red). Transforms outside any shapes will still remain.")


func _process_transforms(transforms, domain, seed) -> void:
	var i := 0
	var point: Vector3
	var to_remove := false

	while i < transforms.size():
		point = transforms.list[i].origin

		if exclusive_shapes_only:
			to_remove = domain.is_point_excluded(point)
		else:
			to_remove = not domain.is_point_inside(point)

		if to_remove:
			transforms.list.remove_at(i)
			continue

		i += 1
