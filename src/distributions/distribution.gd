tool

extends Resource

# Abstract
# Inherit this class and override its functions

class_name Distribution

export(int) var random_seed : int = 0

func reset() -> void:
	pass

func get_float() -> float:
	return 0.0

func get_vector2() -> Vector2:
	return Vector2(get_float(), get_float())

func get_vector3() -> Vector3:
	return Vector3(get_float(), get_float(), get_float())
