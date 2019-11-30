tool
extends "base_modifier.gd"

#changes scale of objects

export(bool) var local = false
export(Vector3) var scale = Vector3(1, 1, 1)


func _init() -> void:
	display_name = "Apply Scale"


func _process_transforms(transforms, _global_seed : int) -> void:
	for t in transforms.list.size():
		transforms.list[t].basis = transforms.list[t].basis.scaled(float(local) * transforms.list[t].basis.xform(scale) + float(!local) * scale)
