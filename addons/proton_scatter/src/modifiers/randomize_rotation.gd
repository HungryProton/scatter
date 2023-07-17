@tool
extends "base_modifier.gd"


@export var rotation := Vector3(360.0, 360.0, 360.0)
@export var snap_angle := Vector3.ZERO

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Randomize Rotation"
	category = "Edit"
	can_override_seed = true
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = true
	use_individual_instances_space_by_default()

	documentation.add_paragraph("Randomly rotate every transforms individually.")

	var p := documentation.add_parameter("Rotation")
	p.set_type("Vector3")
	p.set_description("Rotation angle (in degrees) along each axes (X, Y, Z)")

	p = documentation.add_parameter("Snap angle")
	p.set_type("Vector3")
	p.set_description(
		"When set to any value above 0, the rotation will be done by increments
		of the snap angle.")
	p.add_warning(
		"Example: When Snap Angle is set to 90, the possible random rotation
		offsets around an axis will be among [0, 90, 180, 360].")


func _process_transforms(transforms, domain, random_seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(random_seed)

	var t: Transform3D
	var b: Basis

	var gt: Transform3D = domain.get_global_transform()
	var gb: Basis = gt.basis
	var axis_x: Vector3 = Vector3.RIGHT
	var axis_y: Vector3 = Vector3.UP
	var axis_z: Vector3 = Vector3.FORWARD

	if is_using_local_space():
		axis_x = (Vector3.RIGHT * gb).normalized()
		axis_y = (Vector3.UP * gb).normalized()
		axis_z = (Vector3.FORWARD * gb).normalized()

	for i in transforms.list.size():
		t = transforms.list[i]
		b = t.basis

		if is_using_individual_instances_space():
			axis_x = t.basis.x.normalized()
			axis_y = t.basis.y.normalized()
			axis_z = t.basis.z.normalized()

		b = b.rotated(axis_x, _random_angle(rotation.x, snap_angle.x))
		b = b.rotated(axis_y, _random_angle(rotation.y, snap_angle.y))
		b = b.rotated(axis_z, _random_angle(rotation.z, snap_angle.z))

		t.basis = b
		transforms.list[i] = t


func _random_vec3() -> Vector3:
	var vec3 = Vector3.ZERO
	vec3.x = _rng.randf_range(-1.0, 1.0)
	vec3.y = _rng.randf_range(-1.0, 1.0)
	vec3.z = _rng.randf_range(-1.0, 1.0)
	return vec3


func _random_angle(rot: float, snap: float) -> float:
	return deg_to_rad(snapped(_rng.randf_range(-1.0, 1.0) * rot, snap))


func _clamp_vector(vec3, vmin, vmax) -> Vector3:
	vec3.x = clamp(vec3.x, vmin.x, vmax.x)
	vec3.y = clamp(vec3.y, vmin.y, vmax.y)
	vec3.z = clamp(vec3.z, vmin.z, vmax.z)
	return vec3
