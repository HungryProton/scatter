@tool
extends "base_modifier.gd"


@export var amount := 10

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Create Inside (Random)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_override_seed = true

	documentation.add_paragraph(
		"""Randomly place new transforms in the area defined by
		the ScatterShape nodes""")
	documentation.add_parameter(
		"Amount",
		"How many transforms will be created.")
	documentation.add_warning(
		"""In some cases, the amount of transforms created by this modifier
		might be lower than the requested amount (but never higher). This is to
		prevent an infinite loop if the provided ScatterShape has a huge
		bounding box but a tiny valid space, like a curved path.""")


func _process_transforms(transforms, domain, seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(seed)

	var gt: Transform3D = domain.get_global_transform()
	var center: Vector3 = domain.bounds.center
	var half_size: Vector3 = domain.bounds.size / 2.0
	var height: float = domain.bounds.center.y

	# Generate a random point in the bounding box. Store if it's inside the
	# domain, or discard if invalid. Repeat until enough valid points are found.
	var positions := []
	var max_retries = amount * 10
	var tries := 0

	while positions.size() != amount:
		var pos = _random_vec3() * half_size + center
		if domain.is_point_inside(pos):
			if restrict_height:
				pos.y = height
			positions.push_back(pos)

		# Prevents an infinite loop
		tries += 1
		if tries > max_retries:
			break

	#print("positions ", positions)

	# Create the new transforms using the previously generated array
	# TODO: maybe generate the transforms directly to avoid a second loop and
	# append the array directly
	var start_index = transforms.list.size()
	transforms.add(positions.size())
	for i in positions.size():
		transforms.list[start_index + i].origin = positions[i]


func _random_vec3() -> Vector3:
	var vec3 = Vector3.ZERO
	vec3.x = _rng.randf_range(-1.0, 1.0)
	vec3.y = _rng.randf_range(-1.0, 1.0)
	vec3.z = _rng.randf_range(-1.0, 1.0)
	return vec3
