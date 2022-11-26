@tool
extends "base_modifier.gd"


@export var target := Vector3.ZERO
@export var up := Vector3.UP


func _init() -> void:
	display_name = "Look At"
	category = "Edit"
	can_use_global_and_local_space = true
	can_restrict_height = false

	documentation.add_paragraph("Rotates every transform such that the forward axis (-Z) points towards the target position.")

	documentation.add_parameter("Target").set_type("Vector3").set_description(
		"Target position (X, Y, Z)")
	documentation.add_parameter("Up").set_type("Vector3").set_description(
		"Up axes (X, Y, Z)")


func _process_transforms(transforms, domain, _seed : int) -> void:
	for t in transforms.list.size():
		var transform = transforms.list[t]
		var origin = transform.origin
		var original_scale = transform.basis.get_scale()
		var local_target:Vector3 = target-origin
		if use_local_space:
			#target is local so it should be global for the looking_at
			local_target = domain.get_global_transform()*target-origin
		var lookat:Transform3D = Transform3D(Basis.looking_at(local_target, up), origin)
		lookat = lookat.scaled_local(original_scale)
		transforms.list[t]=lookat
