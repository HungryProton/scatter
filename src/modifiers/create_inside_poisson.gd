@tool
extends "base_modifier.gd"


@export var distribution_radius := 1.0
@export var distribution_retries := 20

var _sampler = preload("../common/poisson_disc_sampling.gd").new()


func _init() -> void:
	display_name = "Create Inside (Poisson)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_restrict_height = false # TMP, TODO: Make a 3D poisson sampling lib


func _process_transforms(transforms, domain, seed) -> void:
	_sampler.rng = RandomNumberGenerator.new()
	_sampler.rng.set_seed(seed)

	var rect_pos = Vector2(domain.bounds.min.x, domain.bounds.min.z)
	var rect_size = Vector2(domain.bounds.size.x, domain.bounds.size.z)
	var bounds = Rect2(rect_pos, rect_size)
	var retries = distribution_retries
	if transforms.max_count >= 0:
		retries = 1

	var t: Transform3D
	var new_transforms: Array[Transform3D] = []
	var samples = _sampler.generate_points(distribution_radius, bounds, retries)

	for s in samples:
		if domain.is_point_inside(Vector3(s.x, 0.0, s.y)):
			t = Transform3D()
			t.origin = Vector3(s.x, 0.0, s.y)
			new_transforms.push_back(t)

	transforms.append(new_transforms)
