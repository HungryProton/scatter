tool
extends Node


export(bool) var override_global_seed = false
export(int) var custom_seed = 0
export(bool) var local_space = false
export(Vector3) var position = Vector3.ONE
export(Vector3) var rotation = Vector3(360.0, 360.0, 360.0)
export(Vector3) var scale = Vector3.ONE


var display_name := "Randomize Transforms"

var _rng: RandomNumberGenerator


func process_transforms(transforms, global_seed) -> void:
	_rng = RandomNumberGenerator.new()

	if override_global_seed:
		_rng.set_seed(custom_seed)
	else:
		_rng.set_seed(global_seed)
	
	var t: Transform
	var origin: Vector3
	var s: Vector3
	for i in transforms.list.size():
		t = transforms.list[i]
		origin = t.origin
		t.origin = Vector3.ZERO
		
		s = Vector3.ONE + (_rng.randf() * scale)
		# scale = _clamp_vector(scale, Vector3.ZERO, scale)
		t = t.scaled(s)
		
		t = t.rotated(Vector3.RIGHT, deg2rad(_random_float() * rotation.x))
		t = t.rotated(Vector3.UP, deg2rad(_random_float() * rotation.y))
		t = t.rotated(Vector3.BACK, deg2rad(_random_float() * rotation.z))
		
		if local_space:
			t.origin = origin + t.xform(_random_vec3() * position)
		else:
			t.origin = origin + _random_vec3() * position
		
		transforms.list[i] = t


func _random_vec3() -> Vector3:
	var vec3 = Vector3.ZERO
	vec3.x = _rng.randf_range(-1.0, 1.0)
	vec3.y = _rng.randf_range(-1.0, 1.0)
	vec3.z = _rng.randf_range(-1.0, 1.0)
	return vec3


func _random_float() -> float:
	return _rng.randf_range(-1.0, 1.0)


func _clamp_vector(vec3, vmin, vmax) -> Vector3:
	vec3.x = clamp(vec3.x, vmin.x, vmax.x)
	vec3.y = clamp(vec3.y, vmin.y, vmax.y)
	vec3.z = clamp(vec3.z, vmin.z, vmax.z)
	return vec3
