# --
# Distribution Uniform
# --
# Simple random distribution that uses the built in RandomNumberGenerator class
# --

tool

extends ScatterDistribution

class_name DistributionUniform

## --
## Internal variables
## --

var _rand = RandomNumberGenerator.new()

## --
## Public methods
## --

func reset() -> void:
	_rand.set_seed(random_seed)

func get_float() -> float:
	return _rand.randf_range(range_1d.x, range_1d.y)

func get_float_range(rmin = 0.0, rmax = 1.0):
	return _rand.randf_range(rmin, rmax)

func get_vector3() -> Vector3:
	var v = Vector3.ZERO
	v.x = get_float_range(range_x.x, range_x.y)
	v.y = get_float_range(range_y.x, range_y.y)
	v.z = get_float_range(range_z.x, range_z.y)
	return v

## --
## Internal methods
## --
