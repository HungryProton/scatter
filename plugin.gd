@tool
extends EditorPlugin


const Scatter = preload("./src/scatter.gd")
const ModifierStackPlugin = preload("./src/stack/inspector_plugin/modifier_stack_plugin.gd")
const ShapeGizmoPlugin = preload("./src/shapes/gizmos_plugin/shape_gizmo_plugin.gd")

var _modifier_stack_plugin: EditorInspectorPlugin = ModifierStackPlugin.new()
var _shape_gizmo_plugin: EditorNode3DGizmoPlugin = ShapeGizmoPlugin.new()


func get_name():
	return "ProtonScatter"


func _enter_tree():
	add_inspector_plugin(_modifier_stack_plugin)
	add_spatial_gizmo_plugin(_shape_gizmo_plugin)
	_shape_gizmo_plugin.set_undo_redo(get_undo_redo())

	add_custom_type(
		"ProtonScatter",
		"Node3D",
		preload("./src/scatter.gd"),
		preload("./icons/scatter.svg")
	)
	add_custom_type(
		"ScatterItem",
		"Node3D",
		preload("./src/scatter_item.gd"),
		preload("./icons/item.svg")
	)
	add_custom_type(
		"ScatterShape",
		"Node3D",
		preload("./src/scatter_shape.gd"),
		preload("./icons/item.svg")
	)

	var editor_selection = get_editor_interface().get_selection()
	editor_selection.selection_changed.connect(_on_selection_changed)

	scene_changed.connect(_on_scene_changed)


func _exit_tree():
	remove_custom_type("ProtonScatter")
	remove_custom_type("ScatterItem")
	remove_custom_type("ScatterShape")
	remove_inspector_plugin(_modifier_stack_plugin)
	remove_spatial_gizmo_plugin(_shape_gizmo_plugin)


func _on_selection_changed() -> void:
	var selected = get_editor_interface().get_selection().get_selected_nodes()

	if selected.is_empty():
		return

	if selected[0] is Scatter:
		selected[0].undo_redo = get_undo_redo()


func _on_scene_changed(_scene_root) -> void:
	pass
