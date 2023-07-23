@tool
extends "base_modifier.gd"


const ProtonScatter := preload("../scatter.gd")
const ModifierStack := preload("../stack/modifier_stack.gd")


@export_node_path var scatter_node: NodePath
@export var auto_rebuild := true:
	set(val):
		auto_rebuild = val
		if not is_instance_valid(_source_node) or not _source_node is ProtonScatter:
			return

		if auto_rebuild: # Connect signal if not already connected
			if not _source_node.build_completed.is_connected(_on_source_changed):
				_source_node.build_completed.connect(_on_source_changed)

		# Auto rebuild disabled, disconnect signal if connected
		elif _source_node.build_completed.is_connected(_on_source_changed):
			_source_node.build_completed.disconnect(_on_source_changed)

var _source_node: ProtonScatter:
	set(val):
		# Disconnect signals from previous scatter node if any
		if is_instance_valid(_source_node) and _source_node is ProtonScatter:
			if _source_node.build_completed.is_connected(_on_source_changed):
				_source_node.build_completed.disconnect(_on_source_changed)

		# Replace reference and retrigger the auto_rebuild setter
		_source_node = val
		auto_rebuild = auto_rebuild


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
	_source_node = domain.get_root().get_node_or_null(scatter_node)

	if not _source_node or not _source_node is ProtonScatter:
		warning += "You need to select a valid ProtonScatter node."
		return

	if _source_node.modifier_stack:
		var stack: ModifierStack = _source_node.modifier_stack.get_copy()
		var results = await stack.start_update(domain.get_root(), domain)
		transforms.append(results.list)


func _on_source_changed() -> void:
	modifier_changed.emit()
