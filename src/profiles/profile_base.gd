# --
# Scatter Profile
# --
# Abstract class to define small blocs that can be reused accross multiple
# positioning resources.
# --

tool

extends ScatterResource

class_name ScatterProfile

## --
## Public methods
## --

# Mostly used to reset the random generator and do one time initialization
func reset() -> void:
	pass

func set_parameter(variant1, variant2) -> void:
	pass

func get_result(variant):
	return null
