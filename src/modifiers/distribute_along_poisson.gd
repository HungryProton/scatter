tool
extends "base_modifier.gd"

export var override_global_seed := false
export var custom_seed := 0
export var width : float = 1.0
export var distribution_radius := 1.0
export var distribution_retries := 20
export var align_to_path := false
export var align_up_axis := 1
export var restrict_x := false
export var restrict_y := false
export var restrict_z := false

var _sampler = preload("../common/poisson_disc_sampling.gd").new()


func _init() -> void:
	display_name = "Distribute Along Path (Poisson)"
	category = "Distribute"
	warning_ignore_no_transforms = true
	warning_ignore_no_path = false


func _process_transforms(transforms, global_seed) -> void:
	_sampler.rng = RandomNumberGenerator.new()

	if override_global_seed:
		_sampler.rng.set_seed(custom_seed)
	else:
		_sampler.rng.set_seed(global_seed)

	var rect_pos = Vector2(transforms.path.bounds_min.x - width, transforms.path.bounds_min.z - width)
	var rect_size = Vector2(transforms.path.size.x + (width * 2), transforms.path.size.z + (width * 2)) 
	var bounds = Rect2(rect_pos, rect_size)
	var retries = distribution_retries
	if transforms.max_count >= 0:
		retries = 1

	var samples = _sampler.generate_points(distribution_radius, bounds, retries)
	transforms.resize(samples.size())

	if transforms.list.size() == 0:
		transforms.add(samples.size())

	var matched_samples: int = 0
	for s in samples:
		if matched_samples == transforms.list.size():
			break
		var s3 = Vector3(s.x, 0, s.y)
		var p = transforms.path.curve.get_closest_point(s3) #closest point
		if (p - s3).length() < width:
			transforms.list[matched_samples].origin = Vector3(s.x, transforms.list[matched_samples].origin.y, s.y)
			if align_to_path:
				var data = transforms.path.get_pos_and_normal(transforms.path.curve.get_closest_offset(p))
				var pos: Vector3 = data[0]
				var normal: Vector3 = data[1]
				
				#axis restrictions
				normal.x *= int(!restrict_x)
				normal.y *= int(!restrict_y)
				normal.z *= int(!restrict_z)
				#this does not like restricting both x and z simulatneously

				transforms.list[matched_samples] = transforms.list[matched_samples].looking_at(
					transforms.list[matched_samples].origin + normal, 
					get_align_up_vector(align_up_axis))
			#transforms.list[matched_samples].basis = 
			matched_samples += 1

	transforms.list.resize(matched_samples)
	shuffle(transforms.list, _sampler.rng.get_seed())
	
	
static func get_align_up_vector(align : int) -> Vector3:
	var axis : Vector3
	match align:
		#x
		0:
			axis = Vector3.RIGHT
		#y
		1:
			axis = Vector3.UP
		#z
		2:
			axis = Vector3.BACK
		_:
			#default return y axis
			axis = Vector3.UP

	return axis
