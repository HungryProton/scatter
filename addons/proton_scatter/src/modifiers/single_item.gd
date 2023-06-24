@tool
extends "base_modifier.gd"

# Adds a single object with the given transform

@export var offset := Vector3.ZERO
@export var rotation := Vector3.ZERO
@export var scale := Vector3.ONE


func _init() -> void:
	display_name = "Add Single Item"
	category = "Create"
	warning_ignore_no_shape = true
	warning_ignore_no_transforms = true
	can_restrict_height = false
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = false
	use_local_space_by_default()


func _process_transforms(transforms, domain, _seed) -> void:
	var gt: Transform3D = domain.get_global_transform()
	var gt_inverse: Transform3D = gt.affine_inverse()

	var t_origin := offset
	var basis := Basis()
	var x_axis = Vector3.RIGHT
	var y_axis = Vector3.UP
	var z_axis = Vector3.FORWARD

	if is_using_global_space():
		t_origin = gt_inverse.basis * t_origin
		x_axis = gt_inverse.basis * x_axis
		y_axis = gt_inverse.basis * y_axis
		z_axis = gt_inverse.basis * z_axis
		basis = gt_inverse.basis

	basis = basis.rotated(x_axis, deg_to_rad(rotation.x))
	basis = basis.rotated(y_axis, deg_to_rad(rotation.y))
	basis = basis.rotated(z_axis, deg_to_rad(rotation.z))

	var transform := Transform3D(basis, Vector3.ZERO)

	if is_using_global_space():
		var global_t: Transform3D = gt * transform
		global_t.basis = global_t.basis.scaled(scale)
		transform = gt_inverse * global_t
	else:
		transform = transform.scaled_local(scale)

	transform.origin = t_origin

	transforms.list.push_back(transform)
