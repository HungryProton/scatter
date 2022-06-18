@tool
extends "base_modifier.gd"


@export var position := Vector3.ZERO


func _init() -> void:
	display_name = "Offset Position"
	category = "Offset"
	can_use_global_and_local_space = true
	can_restrict_height = false


func _process_transforms(transforms, domain, _seed) -> void:
	var t: Transform3D

	for i in transforms.list.size():
		t = transforms.list[i]

		if use_local_space:
			t.origin += t.basis * position
		else:
			t.origin += position

		transforms.list[i] = t
