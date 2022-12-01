@tool
extends "base_modifier.gd"


const Scatter = preload("../scatter.gd")


@export_node_path var scatter_node
#@export var auto_sync_changes := true # TODO: find a solution to this.

var _reference_node


func _init() -> void:
	display_name = "Proxy"
	category = "Misc"
	can_restrict_height = false
	can_override_seed = false
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false
	warning_ignore_no_transforms = true

	documentation.add_paragraph("Copy a modifier stack from another ProtonScatter node in the scene.")
	documentation.add_paragraph(
		"Useful when you need multiple Scatter nodes sharing the same rules, without having to
		replicate their modifiers and settings in each."
	)
	documentation.add_paragraph(
		"Unlike presets which are full independent copies, this method is more similar to a linked
		copy. Changes on the original modifier stack will be accounted for in here."
	)

	var p = documentation.add_parameter("Scatter node")
	p.set_type("NodePath")
	p.set_description("The Scatter node to use as a reference.")


func _process_transforms(transforms, domain, _seed) -> void:
	var reference_node = domain.get_root().get_node_or_null(scatter_node)

	if not reference_node or not reference_node is Scatter:
		warning += "You need to select a valid ProtonScatter node."
		return

	if reference_node.modifier_stack:
		var stack = reference_node.modifier_stack.get_copy()
		var result = stack.update(domain.get_root(), domain)
		transforms.append(result.list)
