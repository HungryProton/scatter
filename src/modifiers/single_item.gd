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
	var basis := Basis()
	basis = basis.rotated(Vector3.RIGHT, deg_to_rad(rotation.x))
	basis = basis.rotated(Vector3.UP, deg_to_rad(rotation.y))
	basis = basis.rotated(Vector3.FORWARD, deg_to_rad(rotation.z))
	var transform := Transform3D(basis, offset)

	if is_using_local_space():
		var gt: Transform3D = domain.get_global_transform()
		transform = gt * transform.scaled_local(scale)
	else:
		transform = transform.scaled(scale)

	transforms.list.push_back(transform)
