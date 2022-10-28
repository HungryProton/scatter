@tool
extends "base_modifier.gd"


@export var rotation := Vector3(360.0, 360.0, 360.0)
@export var snap_angle := Vector3.ZERO

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Randomize Rotation"
	category = "Edit"
	can_restrict_height = false
	can_use_global_and_local_space = true
	use_local_space = true

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


func _process_transforms(transforms, domain, seed) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(seed)

	var t: Transform3D
	var b: Basis

	var gt: Transform3D = domain.get_global_transform()
	var gb: Basis = gt.basis
	var global_x: Vector3 = (Vector3.RIGHT * gb).normalized()
	var global_y: Vector3 = (Vector3.UP * gb).normalized()
	var global_z: Vector3 = (Vector3.FORWARD * gb).normalized()

	for i in transforms.list.size():
		t = transforms.list[i]
		b = t.basis

		if use_local_space:
			b = b.rotated(t.basis.x.normalized(), _random_angle(rotation.x, snap_angle.x))
			b = b.rotated(t.basis.y.normalized(), _random_angle(rotation.y, snap_angle.y))
			b = b.rotated(t.basis.z.normalized(), _random_angle(rotation.z, snap_angle.z))

		else:
			b = b.rotated(global_x, _random_angle(rotation.x, snap_angle.x))
			b = b.rotated(global_y, _random_angle(rotation.y, snap_angle.y))
			b = b.rotated(global_z, _random_angle(rotation.z, snap_angle.z))

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
