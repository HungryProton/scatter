tool
extends "base_modifier.gd"


export var override_global_seed := false
export var custom_seed := 0
export var local_space := false
export var position := Vector3.ONE
export var rotation := Vector3(360.0, 360.0, 360.0)
export var scale := Vector3.ONE

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Randomize Transforms"
	category = "Edit"


func _process_transforms(transforms, global_seed) -> void:
	_rng = RandomNumberGenerator.new()

	if override_global_seed:
		_rng.set_seed(custom_seed)
	else:
		_rng.set_seed(global_seed)

	var t: Transform
	var s: Vector3
	var origin: Vector3

	var gt: Transform = transforms.path.get_global_transform()
	origin = gt.origin
	gt.origin = Vector3.ZERO
	var global_x: Vector3 = gt.xform_inv(Vector3.RIGHT).normalized()
	var global_y: Vector3 = gt.xform_inv(Vector3.UP).normalized()
	var global_z: Vector3 = gt.xform_inv(Vector3.DOWN).normalized()
	gt.origin = origin

	for i in transforms.list.size():
		t = transforms.list[i]
		origin = t.origin
		t.origin = Vector3.ZERO

		s = Vector3.ONE + (_rng.randf() * scale)
		t = t.scaled(s)

		if local_space:
			t = t.rotated(t.basis.x.normalized(), deg2rad(_random_float() * rotation.x))
			t = t.rotated(t.basis.y.normalized(), deg2rad(_random_float() * rotation.y))
			t = t.rotated(t.basis.z.normalized(), deg2rad(_random_float() * rotation.z))
			t.origin = origin + t.xform(_random_vec3() * position)

		else:
			t = t.rotated(global_x, deg2rad(_random_float() * rotation.x))
			t = t.rotated(global_y, deg2rad(_random_float() * rotation.y))
			t = t.rotated(global_z, deg2rad(_random_float() * rotation.z))
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
