tool

extends ScatterDistribution

class_name DistributionUniform

var _rand = RandomNumberGenerator.new()

func reset() -> void:
	_rand.set_seed(random_seed)

func get_float() -> float:
	return _rand.randf_range(-1.0, 1.0)
