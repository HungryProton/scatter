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

	# Create all the physics ray queries
	var gt: Transform3D = domain.get_global_transform()
	var gt_inverse := gt.affine_inverse()
	var queries: Array[PhysicsRayQueryParameters3D] = []
	var exclude_queries: Array[PhysicsRayQueryParameters3D] = []

	for t in transforms.list:
		var start = gt * t.origin
		var end = start
		var dir = ray_direction.normalized()

		if is_using_individual_instances_space():
			dir = t.basis * dir

		elif is_using_local_space():
			dir = gt.basis * dir

		start -= ray_offset * dir
		end += ray_length * dir

		var ray_query := PhysicsRayQueryParameters3D.new()
		ray_query.from = start
		ray_query.to = end
		ray_query.collision_mask = collision_mask

		queries.push_back(ray_query)

		var exclude_query := PhysicsRayQueryParameters3D.new()
		exclude_query.from = start
		exclude_query.to = end
		exclude_query.collision_mask = exclude_mask
		exclude_queries.push_back(exclude_query)

	# Run the queries in the physics helper since we can't access the PhysicsServer
	# from outside the _physics_process while also being in a separate thread.
	var physics_helper: ProtonScatterPhysicsHelper = domain.get_root().get_physics_helper()

	var ray_hits := await physics_helper.execute(queries)

	if ray_hits.is_empty():
		return

	# Create queries from the hit points
	var index := -1
	for ray_hit in ray_hits:
		index += 1
		var hit : Dictionary = ray_hit
		if hit.is_empty():
			exclude_queries[index].collision_mask = 0 # this point is empty anyway, we dont care
			continue
		exclude_queries[index].to = hit.position # only cast up to hit point for correct ordering

	var exclude_hits : Array[Dictionary] = []
	if exclude_mask != 0: # Only cast the rays if it makes any sense
		exclude_hits = await physics_helper.execute(exclude_queries)

	# Apply the results
	index = 0
	var d: float
	var t: Transform3D
	var remapped_max_slope = remap(max_slope, 0.0, 90.0, 0.0, 1.0)
	var is_point_valid := false
	exclude_hits.reverse() # makes it possible to use pop_back which is much faster
	var new_transforms_array : Array[Transform3D] = []

	for hit in ray_hits:
		is_point_valid = true

		if hit.is_empty():
			is_point_valid = false
		else:
			d = abs(Vector3.UP.dot(hit.normal))
			is_point_valid = d >= (1.0 - remapped_max_slope)

		var exclude_hit = exclude_hits.pop_back()
		if exclude_hit != null:
			if not exclude_hit.is_empty():
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
