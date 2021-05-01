tool
extends "base_modifier.gd"


export var override_global_seed := false
export var custom_seed := 0
export var octaves := 4
export var period := 20.0
export var persistence := 0.8
export var scale := Vector3.ONE

var _noise: OpenSimplexNoise


func _init() -> void:
	display_name = "Randomize Scale (Noise)"
	category = "Edit"


func _process_transforms(transforms, global_seed) -> void:
	_noise = OpenSimplexNoise.new()
	_noise.period = period
	_noise.octaves = octaves
	_noise.persistence = persistence

	if override_global_seed:
		_noise.set_seed(custom_seed)
	else:
		_noise.set_seed(global_seed)

	var t: Transform
	var origin: Vector3
	var s: Vector3
	for i in transforms.list.size():
		t = transforms.list[i]
		origin = t.origin
		t.origin = Vector3.ZERO

		s = _randf(origin) * scale
		t = t.scaled(Vector3.ONE + s)

		t.origin = origin
		transforms.list[i] = t


func _randf(pos) -> float:
	return (_noise.get_noise_3dv(pos) + 1.0) * 0.5


func _clamp_vector(vec3, vmin, vmax) -> Vector3:
	vec3.x = clamp(vec3.x, vmin.x, vmax.x)
	vec3.y = clamp(vec3.y, vmin.y, vmax.y)
	vec3.z = clamp(vec3.z, vmin.z, vmax.z)
	return vec3
