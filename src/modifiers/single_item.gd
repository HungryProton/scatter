tool
extends "base_modifier.gd"

# Adds a single object with the given transform

export(Vector3) var offset = Vector3.ZERO
export(Vector3) var rotation = Vector3.ZERO
export(Vector3) var scale = Vector3.ZERO


func _init() -> void:
	display_name = "Add Single Item"
	category = "Edit"


func _process_transforms(transforms, _global_seed : int) -> void:
	var basis := Basis(rotation)
	var transform := Transform(basis, offset)
	transform = transform.scaled(scale)

	transforms.push_back(transform)
