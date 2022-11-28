@tool
extends "base_modifier.gd"


@export var target := Vector3.ZERO
@export var up := Vector3.UP


func _init() -> void:
	display_name = "Look At"
	category = "Edit"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_local_space_by_default()

	documentation.add_paragraph("Rotates every transform such that the forward axis (-Z) points towards the target position.")

	documentation.add_parameter("Target").set_type("Vector3").set_description(
		"Target position (X, Y, Z)")
	documentation.add_parameter("Up").set_type("Vector3").set_description(
		"Up axes (X, Y, Z)")


func _process_transforms(transforms, domain, _seed : int) -> void:
	var st: Transform3D = domain.get_global_transform()

	for t in transforms.size():
		var transform: Transform3D = transforms.list[t]
		var origin := transform.origin
		var original_scale := transform.basis.get_scale()
		var local_target := target - origin

		if is_using_local_space():
			local_target = st * local_target
		elif is_using_individual_instances_space():
			local_target = transform * local_target

		var lookat := Transform3D(Basis.looking_at(local_target, up), origin)
		lookat = lookat.scaled_local(original_scale)
		transforms.list[t] = lookat
