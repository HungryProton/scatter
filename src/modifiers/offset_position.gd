tool
extends "base_modifier.gd"


export(bool) var local_space = false
export(Vector3) var position = Vector3.ZERO


func _init() -> void:
	display_name = "Offset Position"
	category = "Offset"


func _process_transforms(transforms, _global_seed) -> void:
	var t: Transform

	for i in transforms.list.size():
		t = transforms.list[i]

		if local_space:
			t.origin += t.basis.xform(position)
		else:
			t.origin += position

		transforms.list[i] = t
