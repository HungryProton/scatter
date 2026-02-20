@tool
extends "base_modifier.gd"


@export var amount := 10

var _rng: RandomNumberGenerator

var _gt_affine_inverse_basis: Basis
var _tasks: Array[Dictionary] = []
var _new_transforms: Array[Transform3D]
var _domain

func _init() -> void:
	display_name = "Create Inside (Random)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_override_seed = true
	global_reference_frame_available = true
	local_reference_frame_available = true
	use_local_space_by_default()

	documentation.add_paragraph(
		"Randomly place new transforms inside the area defined by
		the ScatterShape nodes.")

	var p := documentation.add_parameter("Amount")
	p.set_type("int")
	p.set_description("How many transforms will be created.")
	p.set_cost(2)

	documentation.add_warning(
		"In some cases, the amount of transforms created by this modifier
		might be lower than the requested amount (but never higher). This may
		happen if the provided ScatterShape has a huge bounding box but a tiny
		valid space, like a curved and narrow path.")


# TODO: + Spatial partionning to discard areas outside the domain earlier
func _process_transforms(transforms, domain, random_seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(random_seed)

	_gt_affine_inverse_basis = domain.get_global_transform().affine_inverse().basis
	_domain = domain
	_new_transforms.clear()
	
	# Prepare parts for parallel processing
	# Note this operation is very light, and thus the gains are pretty much negligable
	# (saves about 1/6th of the time on my system, but even with 500k items, 
	# thats just about 60ms; not very noticable).  
	var part_count: int = max(1, OS.get_processor_count() - 2)
	var part_size: int = max(5000, amount / part_count)
	
	_tasks.clear()
	var from: = 0
	var remaining: int = amount
	while remaining > 0:
		var to = from + min(remaining, part_size)
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.set_seed(_rng.randi())
		_tasks.append( { "from" : from, "to": to, "rng" : rng } )
		remaining -= to - from
		from = to

	_new_transforms.resize(amount)

	WorkerThreadPool.wait_for_group_task_completion(
		WorkerThreadPool.add_group_task(_generate_randoms, _tasks.size())
	)

	transforms.append(_new_transforms)
	_new_transforms.clear()
	_domain = null
	
	
func _generate_randoms(task_index: int) -> void:
	var task: Dictionary = _tasks[task_index]

	var from: int = task["from"]
	var to: int = task["to"]
	var rng: RandomNumberGenerator = task["rng"]
	var count: int = to - from
	var generated: int = 0

	# Generate a random point in the bounding box. Store if it's inside the
	# domain, or discard if invalid. Repeat until enough valid points are found.
	var t: Transform3D
	var pos: Vector3
	
	var center = _domain.bounds_local.center
	var half_size = _domain.bounds_local.size / 2.0
	var height = _domain.bounds_local.center.y

	var max_retries = count * 10 # TODO: expose this parameter?

	var tries = 0
	while generated < count:
		t = Transform3D()
		
		pos = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		pos = pos * half_size + center

		if restrict_height:
			pos.y = height

		if is_using_global_space():
			t.basis = _gt_affine_inverse_basis

		if _domain.is_point_inside(pos):
			t.origin = pos
			_new_transforms[from + generated] = t
			generated += 1
			continue

		# Prevents an infinite loop
		tries += 1
		if tries > max_retries:
			break	
