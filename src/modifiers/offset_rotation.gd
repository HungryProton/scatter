tool
extends "base_modifier.gd"


export(bool) var local_space = false
export(Vector3) var rotation = Vector3.ZERO


func _init() -> void:
	display_name = "Offset Rotation"
	category = "Offset"


func _process_transforms(transforms, _global_seed : int) -> void:
	var basis: Basis
	for t in transforms.list.size():
		basis = transforms.list[t].basis

		basis = basis.rotated(float(local_space) * basis.x + float(!local_space) * Vector3(1, 0, 0), rotation.x)
		basis = basis.rotated(float(local_space) * basis.y + float(!local_space) * Vector3(0, 1, 0), rotation.y)
		basis = basis.rotated(float(local_space) * basis.z + float(!local_space) * Vector3(0, 0, 1), rotation.z)

		transforms.list[t].basis = basis
