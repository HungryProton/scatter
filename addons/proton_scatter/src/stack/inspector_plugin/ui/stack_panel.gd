@tool
extends Control


const ModifierPanel := preload("./modifier/modifier_panel.tscn")


@onready var _modifiers_container: Control = $%ModifiersContainer
@onready var _modifiers_popup: PopupPanel = $%ModifiersPopup

var _scatter
var _modifier_stack
var _undo_redo
var _is_ready := false


func _ready():
	_modifiers_popup.add_modifier.connect(_on_modifier_added)
	_modifiers_container.child_moved.connect(_on_modifier_moved)
	%Rebuild.pressed.connect(_on_rebuild_pressed)
	%DocumentationButton.pressed.connect(_on_documentation_requested.bind("ProtonScatter"))
	%LoadPreset.pressed.connect(_on_load_preset_pressed)
	%SavePreset.pressed.connect(_on_save_preset_pressed)

	_is_ready = true
	rebuild_ui()


func set_node(node) -> void:
	if not node:
		return

	_scatter = node
	_undo_redo = _scatter.undo_redo
	%Documentation.set_editor_plugin(_scatter.editor_plugin)
	%Presets.set_editor_plugin(_scatter.editor_plugin)
	rebuild_ui()


func rebuild_ui() -> void:
	if not _is_ready:
		return

	_validate_stack_connections()
	_clear()
	for m in _modifier_stack.stack:
		var ui = ModifierPanel.instantiate()
		_modifiers_container.add_child(ui)
		ui.set_root(_scatter)
		ui.create_ui_for(m)
		ui.removed.connect(_on_modifier_removed.bind(m))
		ui.value_changed.connect(_on_value_changed)
		ui.documentation_requested.connect(_on_documentation_requested.bind(m.display_name))
		ui.duplication_requested.connect(_on_modifier_duplicated.bind(m))


func _clear() -> void:
	for c in _modifiers_container.get_children():
		_modifiers_container.remove_child(c)
		c.queue_free()


func _validate_stack_connections() -> void:
	if not _scatter:
		return

	if _modifier_stack:
		_modifier_stack.stack_changed.disconnect(_on_stack_changed)

	_modifier_stack = _scatter.modifier_stack
	_modifier_stack.stack_changed.connect(_on_stack_changed)

	if _modifier_stack.just_created:
		%Presets.load_default(_scatter)
		_modifier_stack.just_created = false


func _set_children_owner(new_owner: Node, node: Node):
	for child in node.get_children():
		child.set_owner(new_owner)
		if child.get_children().size() > 0:
			_set_children_owner(new_owner, child)


func _get_root_folder() -> String:
	var path: String = get_script().get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_modifier_added(modifier) -> void:
	if _undo_redo:
		_undo_redo.create_action("Create modifier " + modifier.display_name)
		_undo_redo.add_undo_method(_modifier_stack, "remove", modifier)
		_undo_redo.add_do_method(_modifier_stack, "add", modifier)
		_undo_redo.commit_action()
	else:
		_modifier_stack.add(modifier)


func _on_modifier_moved(old_index: int, new_index: int) -> void:
	if _undo_redo:
		_undo_redo.create_action("Move modifier")
		_undo_redo.add_undo_method(_modifier_stack, "move", new_index, old_index)
		_undo_redo.add_do_method(_modifier_stack, "move", old_index, new_index)
		_undo_redo.commit_action()
	else:
		_modifier_stack.move(old_index, new_index)


func _on_modifier_removed(modifier) -> void:
	if _undo_redo:
		_undo_redo.create_action("Remove modifier " + modifier.display_name)
		_undo_redo.add_undo_method(_modifier_stack, "add", modifier)
		_undo_redo.add_do_method(_modifier_stack, "remove", modifier)
		_undo_redo.commit_action()
	else:
		_modifier_stack.remove(modifier)


func _on_modifier_duplicated(modifier) -> void:
	var index = _modifier_stack.get_index(modifier)
	if index == -1:
		return

	if _undo_redo:
		_undo_redo.create_action("Duplicate modifier " + modifier.display_name)
		_undo_redo.add_undo_method(_modifier_stack, "remove_at", index + 1)
		_undo_redo.add_do_method(_modifier_stack, "duplicate_modifier", modifier)
		_undo_redo.commit_action()
	else:
		_modifier_stack.duplicate_modifier(modifier)


func _on_stack_changed() -> void:
	rebuild_ui()


func _on_value_changed() -> void:
	_modifier_stack.value_changed.emit()


func _on_rebuild_pressed() -> void:
	if _scatter:
		_scatter.full_rebuild()


func _on_save_preset_pressed() -> void:
	%Presets.save_preset(_scatter)


func _on_load_preset_pressed() -> void:
	%Presets.load_preset(_scatter)


func _on_documentation_requested(page_name) -> void:
	%Documentation.show_page(page_name)
