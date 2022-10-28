@tool
extends "base_modifier.gd"


@export var scale := Vector3(1, 1, 1)


func _init() -> void:
	display_name = "Offset Scale"
	category = "Offset"
	can_use_global_and_local_space = true
	can_restrict_height = false
	use_local_space = true

	documentation.add_paragraph("Scales every transform.")

	documentation.add_parameter("Scale").set_type("Vector3").set_description(
		"How much to scale the transform along each axes (X, Y, Z)")


func _process_transforms(transforms, domain, _seed) -> void:
	var basis: Basis
	for t in transforms.list.size():
		basis = transforms.list[t].basis
		if use_local_space:
			basis.x *= scale.x
			basis.y *= scale.y
			basis.z *= scale.z
		else:
			basis = basis.scaled(scale)

		transforms.list[t].basis = basis
