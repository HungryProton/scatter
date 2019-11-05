extends Node

# Abstract
# Inherit this class and override its functions

class_name Distribution

var _seed : int = 0

func init(seed_number):
	_seed = seed_number

func get_float():
	return 0.0

func get_vector2():
	return Vector2(get_float(), get_float())

func get_vector3():
	return Vector3(get_float(), get_float(), get_float())