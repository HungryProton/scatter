@tool
extends RefCounted

# Abstract class.


var _undo_redo: UndoRedo


func set_undo_redo(ur: UndoRedo) -> void:
	_undo_redo = ur


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
