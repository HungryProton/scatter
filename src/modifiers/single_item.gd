@tool
extends "base_modifier.gd"

# Adds a single object with the given transform

@export var offset := Vector3.ZERO
@export var rotation := Vector3.ZERO
@export var scale := Vector3.ZERO


func _init() -> void:
	display_name = "Add Single Item"
	category = "Create"


func _process_transforms(transforms, _seed) -> void:
	var basis := Basis()
	basis = basis.rotated(Vector3.RIGHT, deg2rad(rotation.x))
	basis = basis.rotated(Vector3.UP, deg2rad(rotation.y))
	basis = basis.rotated(Vector3.FORWARD, deg2rad(rotation.z))
	var transform := Transform3D(basis, offset)
	transform = transform.scaled(scale)
	transforms.push_back(transform)
