tool
extends "base_modifier.gd"


export var local_space := false
export var scale := Vector3(1, 1, 1)


func _init() -> void:
	display_name = "Offset Scale"
	category = "Offset"


func _process_transforms(transforms, _seed) -> void:
	var basis: Basis
	for t in transforms.list.size():
		basis = transforms.list[t].basis
		if local_space:
			basis.x *= scale.x
			basis.y *= scale.y
			basis.z *= scale.z
		else:
			basis = basis.scaled(scale)

		transforms.list[t].basis = basis
