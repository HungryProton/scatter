@tool
extends EditorPlugin


const ProtonScatter := preload("./src/scatter.gd")
const ProtonScatterShape := preload("./src/scatter_shape.gd")
const ModifierStackPlugin := preload("./src/stack/inspector_plugin/modifier_stack_plugin.gd")
const ScatterGizmoPlugin := preload("./src/scatter_gizmo_plugin.gd")
const ShapeGizmoPlugin := preload("./src/shapes/gizmos_plugin/shape_gizmo_plugin.gd")
const PathPanel := preload("./src/shapes/gizmos_plugin/components/path_panel.tscn")
const ScatterCachePlugin := preload("./src/cache/inspector_plugin/scatter_cache_plugin.gd")

var _modifier_stack_plugin := ModifierStackPlugin.new()
var _scatter_gizmo_plugin := ScatterGizmoPlugin.new()
var _shape_gizmo_plugin := ShapeGizmoPlugin.new()
var _scatter_cache_plugin := ScatterCachePlugin.new()
var _path_panel


func _get_plugin_name():
	return "ProtonScatter"


func _enter_tree():
	add_inspector_plugin(_modifier_stack_plugin)
	add_inspector_plugin(_scatter_cache_plugin)

	_path_panel = PathPanel.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _path_panel)
	_path_panel.visible = false

	add_node_3d_gizmo_plugin(_scatter_gizmo_plugin)

	add_node_3d_gizmo_plugin(_shape_gizmo_plugin)
	_shape_gizmo_plugin.set_undo_redo(get_undo_redo())
	_shape_gizmo_plugin.set_path_gizmo_panel(_path_panel)
	_shape_gizmo_plugin.set_editor_plugin(self)

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
		preload("./icons/shape.svg")
	)
	add_custom_type(
		"ScatterCache",
		"Node3D",
		preload("./src/cache/scatter_cache.gd"),
		preload("./icons/cache.svg")
	)

	var editor_selection = get_editor_interface().get_selection()
	editor_selection.selection_changed.connect(_on_selection_changed)

	scene_changed.connect(_on_scene_changed)


func _exit_tree():
	remove_custom_type("ProtonScatter")
	remove_custom_type("ScatterItem")
	remove_custom_type("ScatterShape")
	remove_custom_type("ScatterCache")
	remove_inspector_plugin(_modifier_stack_plugin)
	remove_inspector_plugin(_scatter_cache_plugin)
	remove_node_3d_gizmo_plugin(_shape_gizmo_plugin)
	remove_node_3d_gizmo_plugin(_scatter_gizmo_plugin)
	if _path_panel:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _path_panel)
		_path_panel.queue_free()
		_path_panel = null


func _handles(node) -> bool:
	return node is ProtonScatterShape


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	return _shape_gizmo_plugin.forward_3d_gui_input(viewport_camera, event)


func _on_selection_changed() -> void:
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	_path_panel.selection_changed(selected)

	if selected.is_empty():
		return

	var selected_node = selected[0]
	if selected_node is ProtonScatter:
		selected_node.undo_redo = get_undo_redo()
		selected_node.editor_plugin = self


func _on_scene_changed(_scene_root) -> void:
	pass
