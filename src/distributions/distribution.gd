# --
# Distribution
# --
# Abstract class
# Inherit this class and override its functions
# --

tool

extends Resource

class_name ScatterDistribution

## --
## Imported libraries
## --

## --
## Signals
## --

## --
## Exported variables
## --

export(int) var random_seed : int = 0

## --
## Public variables
## --

## --
## Internal variables
## --

# These variables can be ignored, but it's even better if your custom
# distribution supports them.

# The base PolygonPath. It can be used as a bounding box to constrain
# the range of the generated numbers.
var _path : PolygonPath setget set_base_path

# Exclusion areas are places where the user don't want to see any instances
# Idealy, no Vector2 or Vector3 should fall in this.
var _exclusion_areas : Array setget set_exclusion_areas

## --
## Getters and Setters
## --

func set_base_path(path : PolygonPath) -> void:
	_path = path

func set_exclusion_areas(paths : Array) -> void:
	_exclusion_areas = paths

## --
## Public methods
## --

func reset() -> void:
	pass

# Returns a random float
func get_float() -> float:
	return 0.0

# Returns a random Vector2
func get_vector2() -> Vector2:
	return Vector2(get_float(), get_float())

# Returns a random Vector3
func get_vector3() -> Vector3:
	return Vector3(get_float(), get_float(), get_float())

## --
## Internal methods
## --

## --
## Callbacks
## --
