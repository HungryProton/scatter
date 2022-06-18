@tool
extends "base_modifier.gd"


@export var position := Vector3.ONE
@export var rotation := Vector3(360.0, 360.0, 360.0)
@export var scale := Vector3.ONE

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Randomize Transforms"
	category = "Edit"
	can_override_seed = true
	can_restrict_height = false


func _process_transforms(transforms, domain, seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(seed)

	var t: Transform3D
	var s: Vector3
	var origin: Vector3

	var gt: Transform3D = domain.get_global_transform()
	origin = gt.origin
	gt.origin = Vector3.ZERO
	# Global rotation axis
	var axis_x: Vector3 = (Vector3.RIGHT * gt).normalized()
	var axis_y: Vector3 = (Vector3.UP * gt).normalized()
	var axis_z: Vector3 = (Vector3.DOWN * gt).normalized()
	gt.origin = origin

	for i in transforms.size():
		t = transforms.list[i]
		origin = t.origin
		t.origin = Vector3.ZERO

		s = Vector3.ONE + (_rng.randf() * scale)
		t = t.scaled(s)

		if use_local_space:
			axis_x = t.basis.x.normalized()
			axis_y = t.basis.y.normalized()
			axis_z = t.basis.z.normalized()

		t = t.rotated(axis_x, deg2rad(_random_float() * rotation.x))
		t = t.rotated(axis_y, deg2rad(_random_float() * rotation.y))
		t = t.rotated(axis_z, deg2rad(_random_float() * rotation.z))
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
