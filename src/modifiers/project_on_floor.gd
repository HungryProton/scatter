tool
extends Node


export(float) var ray_length : float = 10.0
export(float) var ray_offset : float = 1.0
export(bool) var remove_points_on_miss = true
export(bool) var invert_ray_direction = false
export(Vector3) var floor_direction = Vector3.DOWN

var display_name := "Project On Floor"


func process_transforms(transforms, _seed) -> void:
	var path = transforms.path
	var space_state = path.get_world().get_direct_space_state()
	
	var pos
	var i := 0
	while i < transforms.list.size():
		pos = _project_on_floor(transforms.list[i].origin, path, space_state)
		if pos != null:
			transforms.list[i].origin = pos
		elif remove_points_on_miss:
			transforms.list.remove(i)
			continue
		i += 1


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

	var hit = space_state.intersect_ray(start, end)
	if hit:
		return path.to_local(hit.position)
	else:
		return null
