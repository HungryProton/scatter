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
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_individual_instances_space_by_default()


func _process_transforms(transforms, domain, seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(seed)

	var t: Transform3D
	var local_t: Transform3D
	var basis: Basis
	var random_scale: Vector3
	var random_position: Vector3
	var st: Transform3D = domain.get_global_transform()

	# Global rotation axis
	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.DOWN

	if is_using_local_space():
		axis_x = st.basis.x
		axis_y = st.basis.y
		axis_z = st.basis.z

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		random_scale = Vector3.ONE + (_rng.randf() * scale)
		random_position = _random_vec3() * position

		if is_using_individual_instances_space():
			axis_x = basis.x
			axis_y = basis.y
			axis_z = basis.z
			basis.x *= random_scale.x
			basis.y *= random_scale.y
			basis.z *= random_scale.z
			random_position = t.basis * random_position

		elif is_using_local_space():
			local_t = t * st
			local_t.basis = local_t.basis.scaled(random_scale)
			basis = (st * local_t).basis

		else:
			basis = basis.scaled(random_scale)

		basis = basis.rotated(axis_x, deg_to_rad(_random_float() * rotation.x))
		basis = basis.rotated(axis_y, deg_to_rad(_random_float() * rotation.y))
		basis = basis.rotated(axis_z, deg_to_rad(_random_float() * rotation.z))

		t.origin += random_position
		t.basis = basis

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
