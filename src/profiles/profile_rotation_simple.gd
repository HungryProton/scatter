# --
# Profile Scaling Simple
# --
# Detailled description
# --

tool

extends ScatterProfile

class_name ProfileRotationSimple

## --
## Signals
## --

## --
## Exported variables
## --

export(Vector3) var offset : Vector3 = Vector3.ZERO setget _set_offset
export(Vector3) var randomness : Vector3 = Vector3(0.0, 90.0, 0.0) setget _set_randomness
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

func _set_offset(val):
	offset = val
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
	var s = offset + distribution.get_float() * randomness / 2.0
	return Vector3(deg2rad(s.x), deg2rad(s.y), deg2rad(s.z))

## --
## Internal methods
## --

## --
## Callbacks
## --
