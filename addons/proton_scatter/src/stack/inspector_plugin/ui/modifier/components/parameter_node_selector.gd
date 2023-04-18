@tool
extends "base_parameter.gd"


@onready var _label: Label = $%Label
@onready var _select_button: Button = $%SelectButton
@onready var _clear_button: Button = $%ClearButton
@onready var _popup: ConfirmationDialog = $%ConfirmationDialog
@onready var _tree: Tree = $%Tree

var _full_path: NodePath
var _root: Node
var _selected: Node


func set_root(root) -> void:
	_root = root


func set_parameter_name(text: String) -> void:
	_label.text = text


func _set_value(val) -> void:
	if val == null:
		return

	_full_path = val

	if val.is_empty():
		return

	_select_button.text = val.get_name(val.get_name_count() - 1)

	if _root and _root.has_node(val):
		_selected = _root.get_node(val)

	if val.is_empty():
		_select_button.text = "Select a node"


func get_value() -> NodePath:
	#if _root and _selected:
	#	_full_path = String(_root.get_path_to(_selected))
	return _full_path


func _populate_tree() -> void:
	_tree.clear()
	var scene_root: Node = get_tree().get_edited_scene_root()

	var tmp = EditorPlugin.new() # TODO: check if this works in release builds
	var gui: Control = tmp.get_editor_interface().get_base_control()
	var editor_theme = gui.get_theme()
	tmp.queue_free()

	_create_items_recursive(scene_root, null, editor_theme)


func _create_items_recursive(node, parent, theme) -> void:
	if parent and not node.owner:
		return # Hidden node.

	var node_item = _tree.create_item(parent)
	node_item.set_text(0, node.get_name())
	node_item.set_meta("node", node)
	node_item.set_icon(0, theme.get_icon(node.get_class(), "EditorIcons"))

	for child in node.get_children():
		_create_items_recursive(child, node_item, theme)


func _on_select_button_pressed() -> void:
	_populate_tree()
	_popup.popup_centered(Vector2i(400, 600))


func _on_clear_button_pressed() -> void:
	_select_button.text = "Select a node"
	_full_path = NodePath()


func _on_node_selected():
	var node = _tree.get_selected().get_meta("node")
	_set_value(_root.get_path_to(node))
	_on_value_changed(get_value())
