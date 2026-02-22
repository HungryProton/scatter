@tool
extends "base_modifier.gd"

const ProtonScatterParallel: = preload("../common/parallel.gd")
const ProtonScatterDomain := preload("../common/domain.gd")

@export var amount := 10


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
func _process_transforms(transforms, domain, rng) -> void:
	# Prepare parts for parallel processing
	# Note this operation is very light, and thus the gains are pretty much negligable
	# (saves about 1/6th of the time on my system, but even with 500k items, 
	# thats just about 60ms). However, when transforming items in 3D view, 
	# every ounce of responsiveness counts.
	var outputs: Array
	
	var parallel: ProtonScatterParallel = ProtonScatterParallel.new()
	parallel.set_rng_seed(rng.seed)
	
	parallel.prepare("create_inside_random", amount, -1, _generate_randoms, 
		func(index: int, task: Dictionary):
			var output: Array[Transform3D] = []
			outputs.append(output)
			task["domain"] = domain
			task["output"] = output
		
			# Prevent calling global transform from non-main thread, resuling in identity
			task["basis"] = domain.get_global_transform().affine_inverse().basis
			
			# Prevent taking the same sequence, but base sequences on the same root
			task["rng"] = RandomNumberGenerator.new()
			task["rng"].set_seed(rng.randi())
	)
	
	await parallel.execute_all()

	for new_transforms: Array[Transform3D] in outputs:
		transforms.append(new_transforms)
	
	
func _generate_randoms(task: Dictionary) -> void:
	var from: int = task["from"]
	var to: int = task["to"]
	var rng: RandomNumberGenerator = task["rng"]
	var output: Array[Transform3D] = task["output"] 
	var domain: ProtonScatterDomain = task["domain"]

	var center: Vector3 = domain.bounds_local.center
	var half_size: Vector3 = domain.bounds_local.size / 2.0
	var height: float = domain.bounds_local.center.y
	var basis: Basis = task["basis"]

	var count: int = to - from
	var generated: int = 0

	# Generate a random point in the bounding box. Store if it's inside the
	# domain, or discard if invalid. Repeat until enough valid points are found.
	var t: Transform3D
	var pos: Vector3

	var max_retries = count * 10 # TODO: expose this parameter?

	var tries = 0
	while generated < count:
		t = Transform3D()

		pos = Vector3(rng.randf_range(-1.0, 1.0), 
					  rng.randf_range(-1.0, 1.0), 
					  rng.randf_range(-1.0, 1.0))
					
		pos = pos * half_size + center

		if restrict_height:
			pos.y = height

		if is_using_global_space():
			t.basis = basis

		if domain.is_point_inside(pos):
			t.origin = pos
			output.append(t)
			generated += 1
			continue

		# Prevents an infinite loop
		tries += 1
		if tries > max_retries:
			break	
