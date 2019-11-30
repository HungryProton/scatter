# --
# Distribution
# --
# Abstract class
# Inherit this class and override its functions
# --

tool

extends ScatterResource

class_name ScatterDistribution

## --
## Exported variables
## --

export(int) var random_seed : int = 0 setget set_random_seed

## --
## Internal variables
## --

var range_1d : Vector2 = Vector2(-1.0, 1.0) setget set_range
var range_x : Vector2 = Vector2(-1.0, 1.0)
var range_y : Vector2 = Vector2(-1.0, 1.0)
var range_z : Vector2 = Vector2(-1.0, 1.0)

## --
## Getters and Setters
## --

func set_random_seed(val) -> void:
	random_seed = val
	notify_update()

func set_range(val) -> void:
	range_1d = val

func set_bounding_box(size, center) -> void:
	range_x.x = center.x - size.x / 2.0
	range_x.y = center.x + size.x / 2.0
	range_y.x = center.y - size.y / 2.0
	range_y.y = center.y + size.y / 2.0
	range_z.x = center.z - size.z / 2.0
	range_z.y = center.z + size.z / 2.0

## --
## Public methods
## --

func reset() -> void:
	pass

# Returns a random float within the range_1d
func get_float() -> float:
	return 0.0

# Returns a random float within the given range
func get_float_range(rand_min = 0.0, rand_max = 1.0) -> float:
	return 0.0

func get_int() -> int:
	return int(get_float())

func get_int_range(rand_min = 0.0, rand_max = 1.0) -> int:
	return int(get_float_range(rand_min, rand_max))

# Returns a random Vector2
func get_vector2() -> Vector2:
	return Vector2(get_float(), get_float())

# Returns a random Vector3
func get_vector3() -> Vector3:
	return Vector3(get_float(), get_float(), get_float())
