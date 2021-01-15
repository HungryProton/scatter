tool
extends "base_modifier.gd"


#changes translation of objects

export(bool) var local = false
export(Vector3) var offset = Vector3.ZERO



func _init() -> void:
	display_name = "Apply Offset"


func _process_transforms(transforms, _global_seed : int) -> void:
	for t in transforms.list.size():
		transforms.list[t].origin += float(local) * transforms.list[t].basis.xform(offset) + float(!local) * offset

