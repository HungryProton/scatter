tool
extends "base_modifier.gd"


export(float) var ray_length : float = 10.0
export(float) var ray_offset : float = 1.0
export(bool) var remove_points_on_miss = true
export(bool) var align_with_floor_normal = false
export(bool) var invert_ray_direction = false
export(Vector3) var floor_direction = Vector3.DOWN


func _init() -> void:
	display_name = "Project On Floor"


func _process_transforms(transforms, _seed) -> void:
	if transforms.list.empty():
		return
	
	var path = transforms.path
	var space_state = path.get_world().get_direct_space_state()
	var hit
	var t: Transform
	var i := 0
	
	while i < transforms.list.size():
		t = transforms.list[i]
		hit = _project_on_floor(t.origin, path, space_state)
		
		if hit != null and not hit.empty():
			if align_with_floor_normal:
				t = _align_with(t, hit.normal)
			t.origin = path.to_local(hit.position)
			transforms.list[i] = t
		
		elif remove_points_on_miss:
			transforms.list.remove(i)
			continue
		
		i += 1

	if transforms.list.empty():
		warning += """All the transforms have been removed. Possible reasons: \n
		+ There is no collider close enough to the path.
		+ The Ray length is not long enough.
		+ The floor direction is incorrect.
		"""


func _project_on_floor(pos, path, space_state):
	var start = pos
	var end = pos
	
	if invert_ray_direction:
		start += ray_offset * floor_direction
		end -= ray_length * floor_direction
	else:
		start -= ray_offset * floor_direction
		end += ray_length * floor_direction

	start = path.to_global(start)
	end = path.to_global(end)

	return space_state.intersect_ray(start, end)


func _align_with(t: Transform, normal: Vector3) -> Transform:
	var n1 = t.basis.y.normalized()
	var n2 = normal.normalized()
	
	var cosa = n1.dot(n2)
	var alpha = acos(cosa)
	var axis = n1.cross(n2)
	
	if axis == Vector3.ZERO:
		return t

	return t.rotated(axis.normalized(), alpha)
