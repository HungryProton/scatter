@tool
extends "base_modifier.gd"


signal projection_completed


const ProtonScatterPhysicsHelper := preload("res://addons/proton_scatter/src/common/physics_helper.gd")


@export var ray_direction := Vector3.DOWN
@export var ray_length := 10.0
@export var ray_offset := 1.0
@export var remove_points_on_miss := true
@export var align_with_collision_normal := false
@export_range(0.0, 90.0) var max_slope = 90.0
@export_flags_3d_physics var collision_mask = 1
@export_flags_3d_physics var exclude_mask = 0


func _init() -> void:
	display_name = "Project On Colliders"
	category = "Edit"
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_global_space_by_default()

	documentation.add_paragraph(
		"Moves each transforms along the ray direction until they hit a collider.
		This is useful to avoid floating objects on uneven terrain for example.")

	documentation.add_warning(
		"This modifier only works when physics bodies are around. It will ignore
		simple MeshInstances nodes.")

	var p := documentation.add_parameter("Ray direction")
	p.set_type("Vector3")
	p.set_description(
		"In which direction we look for a collider. This default to the DOWN
		direction by default (look at the ground).")
	p.add_warning(
		"This is relative to the transform is local space is enabled, or aligned
		with the global axis if local space is disabled.")

	p = documentation.add_parameter("Ray length")
	p.set_type("float")
	p.set_description("How far we look for other physics objects.")
	p.set_cost(2)

	p = documentation.add_parameter("Ray offset")
	p.set_type("Vector3")
	p.set_description(
		"Moves back the raycast origin point along the ray direction. This is
		useful if the initial transform is slightly below the ground, which would
		make the raycast miss the collider (since it would start inside).")

	p = documentation.add_parameter("Remove points on miss")
	p.set_type("bool")
	p.set_description(
		"When enabled, if the raycast didn't collide with anything, or collided
		with a surface above the max slope setting, the transform is removed
		from the list.
		This is useful to avoid floating objects that are too far from the rest
		of the scene's geometry.")

	p = documentation.add_parameter("Align with collision normal")
	p.set_type("bool")
	p.set_description(
		"Rotate the transform to align it with the collision normal in case
		the ray cast hit a collider.")

	p = documentation.add_parameter("Max slope")
	p.set_type("float")
	p.set_description(
		"Angle (in degrees) after which the hit is considered invalid.
		When a ray cast hit, the normal of the ray is compared against the
		normal of the hit. If you set the slope to 0°, the ray and the hit
		normal would have to be perfectly aligned to be valid. On the other
		hand, setting the maximum slope to 90° treats every collisions as
		valid regardless of their normals.")

	p = documentation.add_parameter("Mask")
	p.set_description(
		"Only collide with colliders on these layers. Disabled layers will
		be ignored. It's useful to ignore players or npcs that might be on the
		scene when you're editing it.")

	p = documentation.add_parameter("Exclude Mask")
	p.set_description(
		"Tests if the snapping would collide with the selected layers.
		If it collides, the point will be excluded from the list.")


func _process_transforms(transforms, domain, _seed) -> void:
	if transforms.is_empty():
		return
	
#	var perf_start: int = Time.get_ticks_msec()

	# Create all the physics ray queries
	#
	# This is a 'massive-loop' when working with larger sets, so removed as much as possible 
	# indirections, multiplications and stackframes on the inner-side of the loop.
	# - Using value-type array, preventing memory management overhead of allocs and refcounted's
	# - Using 1 contiguous memory array (of value types), allow more cpu cache hits
	#
	# On 100k items, this reduces (on Ryzen 7600) gives 10-30% gains, depending on case.
	# Note those %s are *only noticable* when using large (2500+) batch sizes in the project settings
	# which improves performance dramatically at the cost of longer mainthread stalls.
	
	var rays_from_to_point_pairs: Array[Vector3] = [] # Alternate from-to pairs

	var gt: Transform3D = domain.get_global_transform()
	var gt_inverse := gt.affine_inverse()
		
	var transforms_list: Array[Transform3D] = transforms.list
	var transforms_count: int = transforms_list.size()

	rays_from_to_point_pairs.resize(transforms_count * 2)

	# Save 2x stack frame and a lot if elifs for most common cases
	var is_space_individual: bool = is_using_individual_instances_space()
	var is_space_local: bool = is_using_local_space()
	var is_default: bool = (not is_space_individual) and (not is_space_local)

	# Save on multiplications for most common cases
	var ray_direction_normalized: Vector3 = ray_direction.normalized()
	var default_ray_offset_dir: Vector3 = ray_offset * ray_direction_normalized 
	var default_ray_length_dir: Vector3 = ray_length * ray_direction_normalized 

	var pair_at: int = 0 # Use addition over multiplication (+2 instead of i * 2)
	for i in transforms_count:
		var t: Transform3D = transforms_list[i] # Sequential read of valuetype
		var start = gt * t.origin
		var end = start

		if is_default: # Most common case first
			start -= default_ray_offset_dir
			end += default_ray_length_dir
		elif is_space_individual:
			var dir = ray_direction_normalized
			dir = t.basis * dir
			start -= ray_offset * dir
			end += ray_length * dir
		else: # is_space_local:
			var dir = ray_direction_normalized
			dir = gt.basis * dir
			start -= ray_offset * dir
			end += ray_length * dir

		# Sequential write of value type
		rays_from_to_point_pairs[pair_at] = start
		rays_from_to_point_pairs[pair_at + 1] = end
		pair_at += 2

	# Run the queries in the physics helper since we can't access the PhysicsServer
	# from outside the _physics_process while also being in a separate thread.
	var physics_helper: ProtonScatterPhysicsHelper = domain.get_root().get_physics_helper()

	var ray_hits := await physics_helper.execute(rays_from_to_point_pairs, collision_mask)

	if ray_hits.is_empty():
		return

	# Create exclude queries from the hit points
	var index: int = -1
	for hit: Dictionary in ray_hits:
		index += 1
		var pair_index: int = index * 2 
		if hit.is_empty():
			# this point is empty anyway, we dont care
			rays_from_to_point_pairs[pair_index] = Vector3.INF
			continue
		
		# only cast up to hit point for correct ordering
		rays_from_to_point_pairs[index * 2 + 1] = hit.position 

	var exclude_hits : Array[Dictionary] = []
	if exclude_mask != 0: # Only cast the rays if it makes any sense
		exclude_hits = await physics_helper.execute(rays_from_to_point_pairs, exclude_mask)

	# Apply the results
	index = 0
	var d: float
	var t: Transform3D
	var remapped_max_slope = remap(max_slope, 0.0, 90.0, 0.0, 1.0)
	var is_point_valid := false
	var new_transforms_array : Array[Transform3D] = []

	var has_exclude: bool = exclude_mask > 0

	for hit in ray_hits:
		is_point_valid = true

		if hit.is_empty():
			is_point_valid = false
		else:
			d = abs(Vector3.UP.dot(hit.normal))
			is_point_valid = d >= (1.0 - remapped_max_slope)

			if has_exclude and not exclude_hits[index].is_empty():
				is_point_valid = false

		t = transforms.list[index]
		
		if is_point_valid:
			if align_with_collision_normal:
				t = _align_with(t, gt_inverse.basis * hit.normal)

			t.origin = gt_inverse * hit.position
			new_transforms_array.push_back(t)
		elif not remove_points_on_miss:
			new_transforms_array.push_back(t)

		index += 1

	# All done, store the transforms in the original array
	transforms.list.clear()
	transforms.list.append_array(new_transforms_array) # this avoids memory leak

#	print("Raycasts took " + str(Time.get_ticks_msec() - perf_start) + " for count: " + str(transforms_count))


	if transforms.is_empty():
		warning += """Every points have been removed. Possible reasons include: \n
		+ No collider is close enough to the shapes.
		+ Ray length is too short.
		+ Ray direction is incorrect.
		+ Collision mask is not set properly.
		+ Max slope is too low.
		"""


func _align_with(t: Transform3D, normal: Vector3) -> Transform3D:
	var n1 = t.basis.y.normalized()
	var n2 = normal.normalized()

	var cosa = n1.dot(n2)
	var alpha = acos(cosa)
	var axis = n1.cross(n2)

	if axis == Vector3.ZERO:
		return t

	return t.rotated(axis.normalized(), alpha)
