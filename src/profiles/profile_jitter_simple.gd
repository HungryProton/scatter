# --
# Profile Jitter Simple
# --
# Returns a random offset to be applied to a position later
# --

tool

extends ScatterProfile

class_name ProfileJitterSimple

## --
## Exported variables
## --

export(Vector3) var jitter : Vector3 = Vector3.ZERO setget set_jitter
export(Resource) var distribution setget set_distribution

## --
## Getters and Setters
## --

func set_jitter(val) -> void:
	jitter = val
	notify_update()

func set_distribution(val) -> void:
	if val is ScatterDistribution:
		distribution = val
		ScatterCommon.safe_connect(distribution, "parameter_updated", self, "notify_update")
		notify_update()

## --
## Public methods
## --

func reset() -> void:
	if not distribution:
		self.distribution = DistributionUniform.new()
	distribution.reset()
	distribution.set_range(Vector2(-1.0, 1.0))

func get_result(item : ScatterItem) -> Vector3:
	return distribution.get_vector3() * jitter





