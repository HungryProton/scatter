@tool
extends "base_modifier.gd"


@export var iterations : int = 3
@export var offset_step : float = 0.01
@export var consecutive_step_multiplier : float = 0.5


func _init() -> void:
	display_name = "Relax Position"
	category = "Edit"
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false
	can_restrict_height = true
	restrict_height = true

	documentation.add_warning(
		"This modifier is currently has an O(n²) complexity and will be slow with
		large amounts of points.
		It will be optimized in a later update.",
		1)


func _process_transforms(transforms, domain, _seed) -> void:
	# TODO this can benefit greatly from multithreading
	if transforms.size() < 2:
		return

	var offset := offset_step

	for iteration in iterations:
		for i in transforms.size():
			var min_vector = Vector3.ONE * 99999.0
			var threshold := 99999.0
			var distance := 0.0
			var diff: Vector3

			# Find the closest point
			for j in transforms.size():
				if i == j:
					continue

				diff = transforms.list[i].origin - transforms.list[j].origin
				distance = diff.length_squared()

				if distance < threshold:
					min_vector = diff
					threshold = distance

			if restrict_height:
				min_vector.y = 0.0

			# move away from closest point
			transforms.list[i].origin += min_vector.normalized() * offset

		offset *= consecutive_step_multiplier
