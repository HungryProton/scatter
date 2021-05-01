tool
extends "base_modifier.gd"

export var override_global_seed := false
export var custom_seed := 0
export var distribution_radius := 1.0
export var distribution_retries := 20

var _sampler = preload("../common/poisson_disc_sampling.gd").new()


func _init() -> void:
	display_name = "Distribute Inside (Poisson)"
	category = "Distribute"
	warning_ignore_no_transforms = true


func _process_transforms(transforms, global_seed) -> void:
	_sampler.rng = RandomNumberGenerator.new()

	if override_global_seed:
		_sampler.rng.set_seed(custom_seed)
	else:
		_sampler.rng.set_seed(global_seed)

	var rect_min = Vector2(transforms.path.bounds_min.x, transforms.path.bounds_min.z)
	var samples = _sampler.generate_points(distribution_radius, Rect2(rect_min, Vector2(transforms.path.size.x, transforms.path.size.z)), distribution_retries)
	transforms.resize(samples.size())

	if transforms.list.size() == 0:
		transforms.add(samples.size())

	var matched_samples: int = 0
	for s in samples:
		if matched_samples == transforms.list.size():
			break

		if transforms.path.is_point_inside(Vector3(s.x, 0.0, s.y)):
			transforms.list[matched_samples].origin = Vector3(s.x, transforms.list[matched_samples].origin.y, s.y)
			matched_samples += 1

	transforms.list.resize(matched_samples)
