# --
# Profile Scaling Simple
# --
# Detailled description
# --

tool

extends ScatterProfile

class_name ProfileScaleSimple

## --
## Signals
## --

## --
## Exported variables
## --

export(Vector3) var global_scale : Vector3 = Vector3.ONE setget _set_global_scale
export(Vector3) var randomness : Vector3 = Vector3.ONE setget _set_randomness
export(Resource) var distribution setget _set_distribution

## --
## Public variables
## --

## --
## Internal variables
## --

## --
## Getters and Setters
## --

func _set_global_scale(val):
	global_scale = val
	notify_update()

func _set_randomness(val):
	randomness = val
	notify_update()

func _set_distribution(val):
	if val is ScatterDistribution:
		distribution = val
		notify_update()

## --
## Public methods
## --

func reset() -> void:
	if not distribution:
		distribution = DistributionUniform.new()
	distribution.reset()

func get_result(pos : Vector3) -> Vector3:
	return (Vector3.ONE + abs(distribution.get_float()) * randomness) * global_scale

## --
## Internal methods
## --

## --
## Callbacks
## --
