@tool
extends "base_modifier.gd"


@export var ray_direction := Vector3.DOWN
@export var ray_length := 10.0
@export var ray_offset := 1.0
@export var remove_points_on_miss := true
@export var align_with_collision_normal := false
@export_range(0.0, 90.0) var max_slope = 90.0
@export_flags_3d_physics var mask = 1


func _init() -> void:
	display_name = "Project On Colliders"
	category = "Edit"
	can_use_global_and_local_space = true
	can_restrict_height = false

	documentation.add_paragraph(
		"Moves each transforms along the ray direction until they hit a collider.
		This is useful to avoid floating objects on uneven terrain for example."
	)
	documentation.add_warning(
		"This modifier only works when physics bodies are around. It will ignore
		simple MeshInstances nodes.",
		0
	)
	documentation.add_parameter(
		"Ray direction",
		"In which direction we look for a collider. This default to the DOWN
		direction by default (look at the ground).",
		0,
		"This is relative to the transform is local space is enabled, or aligned
		with the global axis if local space is disabled.",
		0
	)
	documentation.add_parameter(
		"Ray length",
		"How far we look for other physics objects.",
		1
	)
	documentation.add_parameter(
		"Ray offset",
		"Moves back the raycast origin point along the ray direction. This is
		useful if the initial transform is slightly below the ground, which would
		make the raycast miss the collider (since it would start inside).",
		0
	)
	documentation.add_parameter(
		"Remove points on miss",
		"When enabled, if the raycast didn't collide with anything, or collided
		with a surface above the max slope setting, the transform is removed
		from the list.
		This is useful to avoid floating objects that are too far from the rest
		of the scene's geometry.",
		0
	)
	documentation.add_parameter(
		"Align with collision normal",
		"Rotate the transform to align it with the collision normal in case
		the ray cast hit a collider.",
		0
	)
	documentation.add_parameter(
		"Max slope",
		"Angle (in degrees) after which the hit is considered invalid.
		When a ray cast hit, the normal of the ray is compared against the
		normal of the hit. If you set the slope to 0°, the ray and the hit
		normal would have to be perfectly aligned to be valid. On the other
		hand, setting the maximum slope to 90° treats every collisions as
		valid regardless of their normals.",
		0
	)
	documentation.add_parameter(
		"Mask",
		"Only collide with colliders on these layers. Disabled layers will
		be ignored. It's useful to ignore players or npcs that might be on the
		scene when you're editing it.",
		0
	)

func _process_transforms(transforms, domain, _seed) -> void:
	if transforms.list.is_empty():
		return

	var space_state = domain.space_state
	var hit
	var d: float
	var t: Transform3D
	var i := 0
	var remapped_max_slope = remap(max_slope, 0.0, 90.0, 0.0, 1.0)
	var is_point_valid := false

	while i < transforms.size():
		t = transforms.list[i]
		is_point_valid = true
		hit = _project_on_floor(t, domain.root, space_state)

		if hit.is_empty():
			is_point_valid = false
		else:
			d = abs(Vector3.UP.dot(hit.normal))
			is_point_valid = d >= (1.0 - remapped_max_slope)

		if is_point_valid:
			if align_with_collision_normal:
				t = _align_with(t, hit.normal)

			t.origin = hit.position
			transforms.list[i] = t

		elif remove_points_on_miss:
			transforms.list.remove_at(i)
			continue

		i += 1

	if transforms.list.is_empty():
		warning += """Every points have been removed. Possible reasons include: \n
		+ No collider is close enough to the domain.
		+ Ray length is too short.
		+ Ray direction is incorrect.
		+ Collision mask is not set properly.
		+ Max slope is too low.
		"""


func _project_on_floor(t: Transform3D, root: Node3D, physics_state: PhysicsDirectSpaceState3D) -> Dictionary:
	var start = t.origin
	var end = t.origin
	var dir = ray_direction.normalized()

	if use_local_space:
		dir *= t.basis

	start -= ray_offset * dir
	end += ray_length * dir

	var ray_query := PhysicsRayQueryParameters3D.new()
	ray_query.from = start
	ray_query.to = end
	ray_query.collision_mask = mask
	return physics_state.intersect_ray(ray_query)


func _align_with(t: Transform3D, normal: Vector3) -> Transform3D:
	var n1 = t.basis.y.normalized()
	var n2 = normal.normalized()

	var cosa = n1.dot(n2)
	var alpha = acos(cosa)
	var axis = n1.cross(n2)

	if axis == Vector3.ZERO:
		return t

	return t.rotated(axis.normalized(), alpha)
