@tool
extends "base_modifier.gd"


@export var position := Vector3.ZERO
@export var rotation := Vector3.ZERO
@export var scale := Vector3.ZERO

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


func _process_transforms(transforms, domain, random_seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(random_seed)

	var t: Transform3D
	var global_t: Transform3D
	var basis: Basis
	var random_scale: Vector3
	var random_position: Vector3
	var s_gt: Transform3D = domain.get_global_transform()
	var s_gt_inverse := s_gt.affine_inverse()

	# Global rotation axis
	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.DOWN

	if is_using_global_space():
		axis_x = (s_gt_inverse.basis * Vector3.RIGHT).normalized()
		axis_y = (s_gt_inverse.basis * Vector3.UP).normalized()
		axis_z = (s_gt_inverse.basis * Vector3.FORWARD).normalized()

	for i in transforms.size():
		t = transforms.list[i]
		basis = t.basis

		# Apply rotation
		if is_using_individual_instances_space():
			axis_x = basis.x.normalized()
			axis_y = basis.y.normalized()
			axis_z = basis.z.normalized()

		basis = basis.rotated(axis_x, deg_to_rad(_random_float() * rotation.x))
		basis = basis.rotated(axis_y, deg_to_rad(_random_float() * rotation.y))
		basis = basis.rotated(axis_z, deg_to_rad(_random_float() * rotation.z))

		# Apply scale
		random_scale = Vector3.ONE + (_rng.randf() * scale)

		if is_using_individual_instances_space():
			basis.x *= random_scale.x
			basis.y *= random_scale.y
			basis.z *= random_scale.z

		elif is_using_global_space():
			global_t = s_gt * Transform3D(basis, Vector3.ZERO)
			global_t = global_t.scaled(random_scale)
			basis = (s_gt_inverse * global_t).basis

		else:
			basis = basis.scaled(random_scale)

		# Apply position
		random_position = _random_vec3() * position

		if is_using_individual_instances_space():
			random_position = t.basis * random_position

		elif is_using_global_space():
			random_position = s_gt_inverse.basis * random_position

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
