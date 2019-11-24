# --
# GenericPositioning
# --
# Randomly place instances inside the PolygonPath. Supports exclusion zones
# --

tool

extends BasePositioning

class_name GenericPositioning

## --
## Signals
## --

signal parameter_updated

## --
## Exported variables
## --

export(int) var items_amount : int = 10 setget _set_items_amount
export(Resource) var distribution setget _set_distribution
export(bool) var project_on_floor : bool = false
export(float) var ray_down_length : float = 10.0
export(float) var ray_up_length : float = 0.0
export(Vector3) var rotation_randomness : Vector3 = Vector3(0.0, 1.0, 0.0) setget _set_rotation_randomness
export(Vector3) var scale_randomness : Vector3 = Vector3.ONE setget _set_scale
export(Vector3) var global_scale : Vector3 = Vector3.ONE setget _set_global_scale

## --
## Public variables
## --

## --
## Internal variables
## --

## --
## Getters and Setters
## --

func _set_items_amount(val) -> void:
	items_amount = val
	amount = val
	notify_parameter_update()

func _set_distribution(val):
	if val is Distribution:
		distribution = val
		notify_parameter_update()

func _set_rotation_randomness(val):
	rotation_randomness = val
	notify_parameter_update()

func _set_scale(val):
	scale_randomness = val
	notify_parameter_update()

func _set_global_scale(val):
	global_scale = val
	notify_parameter_update()

## --
## Public methods
## --

func init(node : PolygonPath) -> void:
	#self.init(node)
	_path = node
	distribution.reset()

func get_next_transform(item : ScatterItem, index = -1) -> Transform:
	if not distribution:
		distribution = UniformDistribution.new()

	var t = Transform()

	# Update item scaling
	var s = Vector3.ONE + abs(distribution.get_float()) * scale_randomness
	if item.ignore_initial_scale:
		t = t.scaled(s * global_scale * item.scale_modifier)
	else:
		t = t.scaled(s * global_scale * item.scale_modifier * item.initial_scale)

	# Update item rotation
	var rotation = distribution.get_vector3() * rotation_randomness
	if item.ignore_initial_rotation:
		t = t.rotated(Vector3.RIGHT, rotation.x)
		t = t.rotated(Vector3.UP, rotation.y)
		t = t.rotated(Vector3.BACK, rotation.z)
	else:
		t = t.rotated(Vector3.RIGHT, rotation.x + item.initial_rotation.x)
		t = t.rotated(Vector3.UP, rotation.y + item.initial_rotation.y)
		t = t.rotated(Vector3.BACK, rotation.z + item.initial_rotation.z)

	# Update item location
	var pos = _get_next_valid_pos(item)
	var pos_y = 0.0
	if project_on_floor:
		pos_y = _get_ground_position(pos)
	t.origin = Vector3(pos.x, pos_y, pos.z)
	if not item.ignore_initial_position:
		t.origin += item.initial_position
	return t

## --
## Internal methods
## --

func _get_ground_position(pos):
	var space_state = _path.get_world().get_direct_space_state()
	var top = pos
	var bottom = pos
	top.y = ray_up_length
	bottom.y = -ray_down_length

	top = _path.to_global(top)
	bottom = _path.to_global(bottom)

	var hit = space_state.intersect_ray(top, bottom)
	if hit:
		return _path.to_local(hit.position).y
	else:
		return 0.0

func _get_next_valid_pos(item):
	var pos = distribution.get_vector3() * _path.size * 0.5 + _path.center
	var attempts = 0
	var max_attempts = 200
	while not _is_point_valid(pos, item.get_exclusion_areas()) and (attempts < max_attempts):
		pos = distribution.get_vector3() * _path.size * 0.5 + _path.center
		attempts += 1
	return pos

func _is_point_valid(pos, item_excludes):
	if not _path.is_point_inside(pos):
		return false
	if _is_point_in_exclusion_area(pos, item_excludes):
		return false
	return true

func _is_point_in_exclusion_area(pos, exclusion_areas):
	var inside = false
	for i in range(0, exclusion_areas.size()):
		var a = exclusion_areas[i]
		if a.is_point_inside(a.to_local(_path.to_global(pos))):
			inside = true
	return inside

func notify_parameter_update():
	emit_signal("parameter_updated")

## --
## Callbacks
## --
