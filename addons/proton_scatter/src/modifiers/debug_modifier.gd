@tool
extends "base_modifier.gd"


@export var amount := 10
@export var curve := Curve.new()


func _init() -> void:
	display_name = "Debug Modifier"
	category = "Debug"

	documentation.add_paragraph("Only exists for debug purposes")


func _process_transforms(transforms, domain, random_seed) -> void:
	pass

