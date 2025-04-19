@tool
extends "base_modifier.gd"


@export_range(0.0, 100.0) var probability: float = 50.0


func _init() -> void:
	display_name = "Remove Random"
	category = "Remove"
	can_restrict_height = false
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false
	can_override_seed = true

	documentation.add_paragraph(
		"Remove transforms at random.")

	var p := documentation.add_parameter("Probability")
	p.set_type("float")
	p.set_description(
		"The probability to remove a transform, in percent.
		At 0, nothing is removed. At 100, everything is removed.")


func _process_transforms(transforms: TransformList, _domain: Domain, seed: int) -> void:
	var i := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var threshold: float = probability / 100.0

	while i < transforms.size():
		if rng.randf() < threshold:
			transforms.list.remove_at(i)
			continue
		i += 1
