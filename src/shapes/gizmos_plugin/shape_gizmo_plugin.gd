@tool
extends EditorNode3DGizmoPlugin


# Actual logic split in the handler class to avoid cluttering this script as
# we add extra shapes.
#
# Although we could make an actual gizmo per shape type and add the extra type
# check in the 'has_gizmo' function, it causes more issues to the editor
# than it's worth (2 fewer files), so it's done like this instead.


const ScatterShape = preload("../../scatter_shape.gd")
const SphereShape = preload("../sphere_shape.gd")
const PathShape = preload("../path_shape.gd")
const GizmoHandler = preload("./gizmo_handler.gd")


var _handlers: Dictionary


func _init():
	# TODO: Replace hardcoded colors by a setting fetch
	create_material("line", Color(1, 0.7, 0))
	create_handle_material("handle")

	_handlers[SphereShape] = preload("./sphere_gizmo.gd").new()
	_handlers[PathShape]  = preload("./path_gizmo.gd").new()


func _get_gizmo_name() -> String:
	return "ScatterShape"


func _has_gizmo(node) -> bool:
	return node is ScatterShape


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	return _get_handler(gizmo).get_handle_name(gizmo, handle_id, secondary)


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	return _get_handler(gizmo).get_handle_value(gizmo, handle_id, secondary)


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	_get_handler(gizmo).set_handle(gizmo, handle_id, secondary, camera, screen_pos)


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	_get_handler(gizmo).commit_handle(gizmo, handle_id, secondary, restore, cancel)


func _redraw(gizmo: EditorNode3DGizmo):
	_get_handler(gizmo).redraw(self, gizmo)


func _get_handler(gizmo) -> GizmoHandler:
	var null_handler = GizmoHandler.new() # Only so we don't have to check existence later

	var shape_node = gizmo.get_spatial_node()
	if not shape_node or not shape_node is ScatterShape:
		return null_handler

	var shape_resource = shape_node.shape
	if not shape_resource:
		return null_handler

	var shape_type = shape_resource.get_script()
	if not shape_type in _handlers:
		return null_handler

	return _handlers[shape_type]


func set_undo_redo(ur: UndoRedo) -> void:
	for handler_name in _handlers:
		_handlers[handler_name].set_undo_redo(ur)
