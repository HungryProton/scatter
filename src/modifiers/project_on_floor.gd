@tool
extends "base_modifier.gd"


@export var ray_length := 10.0
@export var ray_offset := 1.0
@export var remove_points_on_miss := true
@export var align_with_floor_normal := false
@export var ray_direction := Vector3.DOWN
@export_range(0.0, 1.0) var max_slope = 1.0
@export_flags_3d_physics var mask = 1048575


func _init() -> void:
	display_name = "Project On Floor"
	category = "Edit"
	can_use_global_and_local_space = true
	can_restrict_height = false


func _process_transforms(transforms, domain, _seed) -> void:
	if transforms.list.is_empty():
		return

	var space_state = domain.root.get_world_3d().get_direct_space_state()
	var hit
	var d: float
	var t: Transform3D
	var i := 0

	while i < transforms.size():
		t = transforms.list[i]
		hit = _project_on_floor(t, domain.root, space_state)

		if hit != null and not hit.is_empty():
			d = abs(Vector3.UP.dot(hit.normal))
			if d < (1.0 - max_slope):
				transforms.list.remove(i)
				continue

			if align_with_floor_normal:
				t = _align_with(t, hit.normal)

			t.origin = hit.position
			transforms.list[i] = t

		elif remove_points_on_miss:
			transforms.list.remove_at(i)
			continue

		i += 1

	if transforms.list.is_empty():
		warning += """All the transforms have been removed. Possible reasons: \n
		+ There is no collider close enough to the path.
		+ The ray length is not long enough.
		+ The ray direction is incorrect.
		"""


func _project_on_floor(t: Transform3D, root: Node3D, physics_state: PhysicsDirectSpaceState3D):
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
	ray_query.collision_mask = int(mask)
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
