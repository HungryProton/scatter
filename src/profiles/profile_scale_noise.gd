# --
# Profile Scaling Noise
# --
# Get the scaling value based on an open simplex resource.
# --

tool

extends ScatterProfile

class_name ProfileScaleNoise

## --
## Exported variables
## --

export(Vector3) var global_scale : Vector3 = Vector3.ONE setget _set_global_scale
export(Vector3) var randomness : Vector3 = Vector3.ONE setget _set_randomness
export(OpenSimplexNoise) var noise : OpenSimplexNoise = OpenSimplexNoise.new() setget _set_noise

## --
## Getters and Setters
## --

func _set_global_scale(val):
	global_scale = val
	notify_update()

func _set_randomness(val):
	randomness = val
	notify_update()

func _set_noise(val):
	noise = val
	ScatterCommon.safe_connect(noise, "changed", self, "notify_update")
	notify_update()

## --
## Public methods
## --

func reset() -> void:
	if not noise:
		self.noise = OpenSimplexNoise.new()

func get_result(pos : Vector3) -> Vector3:
	return (Vector3.ONE + abs(noise.get_noise_3dv(pos)) * randomness) * global_scale
