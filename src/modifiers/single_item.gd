tool
extends "base_modifier.gd"

#adds a single object with the given transform

export(Vector3) var offset = Vector3.ZERO
export(Vector3) var rotation = Vector3.ZERO

func _init() -> void:
	display_name = "Single Item"

func _process_transforms(transforms, _global_seed : int) -> void:
	transforms.resize(transforms.list.size() + 1)
	
	var basis := Basis(rotation)
	var transform := Transform(basis, offset)
	
	transforms.list[transforms.list.size() - 1] = transform
