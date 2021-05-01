tool
extends "base_modifier.gd"


export var local_space := false
export var rotation := Vector3.ZERO


func _init() -> void:
	display_name = "Offset Rotation"
	category = "Offset"


func _process_transforms(transforms, _global_seed : int) -> void:
	var rotation_rad := Vector3.ZERO
	rotation_rad.x = deg2rad(rotation.x)
	rotation_rad.y = deg2rad(rotation.y)
	rotation_rad.z = deg2rad(rotation.z)

	var basis: Basis
	var axis: Vector3
	for t in transforms.list.size():
		basis = transforms.list[t].basis

		axis = (float(local_space) * basis.x + float(!local_space) * Vector3(1, 0, 0)).normalized()
		basis = basis.rotated(axis, rotation_rad.x)

		axis = (float(local_space) * basis.y + float(!local_space) * Vector3(0, 1, 0)).normalized()
		basis = basis.rotated(axis, rotation_rad.y)

		axis = (float(local_space) * basis.z + float(!local_space) * Vector3(0, 0, 1)).normalized()
		basis = basis.rotated(axis, rotation_rad.z)

		transforms.list[t].basis = basis
