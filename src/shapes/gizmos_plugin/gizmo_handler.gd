@tool
extends RefCounted

# Abstract class.


var _undo_redo: EditorUndoRedoManager
var _plugin: EditorPlugin


func set_undo_redo(ur: EditorUndoRedoManager) -> void:
	_undo_redo = ur


func set_editor_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	return ""


func get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	return null


func set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	pass


func commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	pass


func redraw(plugin: EditorNode3DGizmoPlugin, gizmo: EditorNode3DGizmo):
	pass


func forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	return false


func is_selected(gizmo: EditorNode3DGizmo) -> bool:
	if not _plugin:
		return true

	var current_node = gizmo.get_node_3d()
	var selected_nodes := _plugin.get_editor_interface().get_selection().get_selected_nodes()

	return current_node in selected_nodes
