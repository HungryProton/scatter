# --
# Profile Position Simple
# --
# Returns positions inside the main path but outside exclusion zones.
# --

tool

extends ScatterProfile

class_name ProfilePositionSimple

## --
## Signals
## --

## --
## Exported variables
## --

export(bool) var project_on_floor : bool = false
export(float) var ray_down_length : float = 10.0
export(float) var ray_up_length : float = 0.0
export(Resource) var distribution setget set_distribution

## --
## Public variables
## --

## --
## Internal variables
## --

var _path : PolygonPath
var _exclusion_areas : Array

## --
## Getters and Setters
## --

func set_distribution(val):
	if val is ScatterDistribution:
		distribution = val
		notify_parameter_update()

func set_parameter(name, value):
	match name:
		"path":
			_path = value
		"exclusion_areas":
			_exclusion_areas = value

## --
## Public methods
## --

func reset() -> void:
	if not distribution:
		distribution = DistributionUniform.new()
	distribution.reset()

func get_result(item : ScatterItem) -> Vector3:
	var pos = _get_next_valid_pos(item)
	var pos_y = 0.0
	if project_on_floor:
		pos_y = _get_ground_position(pos)
	return Vector3(pos.x, pos_y, pos.z)

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
	while not _is_point_valid(pos, _exclusion_areas) and (attempts < max_attempts):
		pos = distribution.get_vector3() * _path.size * 0.5 + _path.center
		attempts += 1
	return pos

func _is_point_valid(pos, item_excludes):
	if not _path.is_point_inside(pos):
		return false
	if ScatterCommon.is_point_in_paths(pos, item_excludes, _path):
		return false
	return true

## --
## Callbacks
## --
