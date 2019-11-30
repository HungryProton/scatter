# --
# DistributionGrid
# --
# Returns numbers rounded to the closest position on grid. Grid size can be
# changed.
# --

tool

extends ScatterDistribution

class_name DistributionGrid

## --
## Imported libraries
## --

## --
## Exported variables
## --

export(Vector3) var grid_size : Vector3 = Vector3.ONE setget set_grid_size

## --
## Public variables
## --

## --
## Internal variables
## --

var _rand = RandomNumberGenerator.new()

## --
## Getters and Setters
## --

func set_grid_size(val) -> void:
	grid_size = val
	notify_update()

## --
## Public methods
## --

func reset() -> void:
	_rand.set_seed(random_seed)

func get_float() -> float:
	return _snap_x(_rand.randf_range(-range_1d.x, range_1d.x))

func get_float_range(rmin = 0.0, rmax = 0.0) -> float:
	return _snap_x(_rand.randf_range(rmin, rmax))

func get_vector2() -> Vector2:
	var v = Vector2.ZERO
	v.x = _snap_x(_rand.randf_range(-range_x.x, range_x.x))
	v.y = _snap_y(_rand.randf_range(-range_y.y, range_y.y))
	return v

func get_vector3() -> Vector3:
	var v = Vector3.ZERO
	v.x = _snap_x(_rand.randf_range(range_x.x, range_x.y))
	v.y = _snap_y(_rand.randf_range(range_y.x, range_y.y))
	v.z = _snap_z(_rand.randf_range(range_z.x, range_z.y))
	return v

## --
## Protected methods
## --

## --
## Internal methods
## --

func _snap(val, size) -> float:
	return stepify(val, size)

func _snap_x(val) -> float:
	return _snap(val, grid_size.x)

func _snap_y(val) -> float:
	return _snap(val, grid_size.y)

func _snap_z(val) -> float:
	return _snap(val, grid_size.z)

## --
## Callbacks
## --

