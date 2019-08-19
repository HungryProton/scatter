extends Distribution

class_name UniformDistribution

var _rand = RandomNumberGenerator.new()

func init(seed_number):
	_seed = seed_number
	_rand.set_seed(_seed)

func get_float():
	return _rand.randf_range(-1.0, 1.0)
