tool
extends "base_point_modifier.gd"


export var override_global_seed := false
export var custom_seed := 0
export var filter_overlaps := false
export var distribution_radius := 1.0
export var distribution_retries := 20

var _sampler = preload("../common/poisson_disc_sampling.gd").new()


func _init() -> void:
	display_name = "Add Around Point (Poisson)"
	category = "Create"
	enabled = true
	warning_ignore_no_transforms = true


func _process_transforms(transforms, global_seed) -> void:
	._process_transforms(transforms, global_seed)

	_sampler.rng = RandomNumberGenerator.new()

	if override_global_seed:
		_sampler.rng.set_seed(custom_seed)
	else:
		_sampler.rng.set_seed(global_seed)

	var height = bounds_max.y
	var size = bounds_max - bounds_min
	var rect_min = Vector2(bounds_min.x, bounds_min.z)
	var samples = _sampler.generate_points(distribution_radius, Rect2(rect_min, Vector2(size.x, size.z)), distribution_retries)

	for s in samples:
		var pos = Vector3(s.x, height, s.y)
		for p in points:
			if is_inside(pos, p):
				var p_pos = t.xform_inv(p.get_global_transform().origin)
				pos.y = p_pos.y
				var t := Transform()
				t.origin = pos
				transforms.list.push_back(t)
				if filter_overlaps:
					break
