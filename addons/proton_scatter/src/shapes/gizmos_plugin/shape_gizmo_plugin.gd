@tool
extends EditorNode3DGizmoPlugin


# Actual logic split in the handler class to avoid cluttering this script as
# we add extra shapes.
#
# Although we could make an actual gizmo per shape type and add the extra type
# check in the 'has_gizmo' function, it causes more issues to the editor
# than it's worth (2 fewer files), so it's done like this instead.


const ScatterShape = preload("../../scatter_shape.gd")
const GizmoHandler = preload("./gizmo_handler.gd")


var _editor_plugin: EditorPlugin
var _handlers: Dictionary


func _init():
	var handle_icon = preload("./icons/main_handle.svg")
	var secondary_handle_icon = preload("./icons/secondary_handle.svg")

	# TODO: Replace hardcoded colors by a setting fetch
	create_material("primary", Color(1, 0.4, 0))
	create_material("secondary", Color(0.4, 0.7, 1.0))
	create_material("tertiary", Color(Color.STEEL_BLUE, 0.2))
	create_custom_material("primary_top", Color(1, 0.4, 0))
	create_custom_material("secondary_top", Color(0.4, 0.7, 1.0))
	create_custom_material("tertiary_top", Color(Color.STEEL_BLUE, 0.1))

	create_material("inclusive", Color(0.9, 0.7, 0.2, 0.15))
	create_material("exclusive", Color(0.9, 0.1, 0.2, 0.15))

	create_handle_material("default_handle")
	create_handle_material("primary_handle", false, handle_icon)
	create_handle_material("secondary_handle", false, secondary_handle_icon)

	_handlers[ProtonScatterSphereShape] = preload("./sphere_gizmo.gd").new()
	_handlers[ProtonScatterPathShape] = preload("./path_gizmo.gd").new()
	_handlers[ProtonScatterBoxShape] = preload("./box_gizmo.gd").new()


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
	if _is_node_selected(gizmo):
		_get_handler(gizmo).redraw(self, gizmo)
	else:
		gizmo.clear()


func forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	for handler in _handlers.values():
		if handler.forward_3d_gui_input(viewport_camera, event):
			return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS


func set_undo_redo(ur: EditorUndoRedoManager) -> void:
	for handler_type in _handlers:
		_handlers[handler_type].set_undo_redo(ur)


func set_path_gizmo_panel(panel: Control) -> void:
	if ProtonScatterPathShape in _handlers:
		_handlers[ProtonScatterPathShape].set_gizmo_panel(panel)


func set_editor_plugin(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin
	for handler_type in _handlers:
		_handlers[handler_type].set_editor_plugin(plugin)


# Creates a standard material displayed on top of everything.
# Only exists because 'create_material() on_top' parameter doesn't seem to work.
func create_custom_material(name: String, color := Color.WHITE):
	var material := StandardMaterial3D.new()
	material.set_blend_mode(StandardMaterial3D.BLEND_MODE_ADD)
	material.set_shading_mode(StandardMaterial3D.SHADING_MODE_UNSHADED)
	material.set_flag(StandardMaterial3D.FLAG_DISABLE_DEPTH_TEST, true)
	material.set_albedo(color)
	material.render_priority = 100

	add_material(name, material)


func _get_handler(gizmo: EditorNode3DGizmo) -> GizmoHandler:
	var null_handler = GizmoHandler.new() # Only so we don't have to check existence later

	var shape_node = gizmo.get_node_3d()
	if not shape_node or not shape_node is ScatterShape:
		return null_handler

	var shape_resource = shape_node.shape
	if not shape_resource:
		return null_handler

	var shape_type = shape_resource.get_script()
	if not shape_type in _handlers:
		return null_handler

	return _handlers[shape_type]


func _is_node_selected(gizmo: EditorNode3DGizmo) -> bool:
	if ProjectSettings.get_setting(_editor_plugin.GIZMO_SETTING):
		return true

	var selected_nodes: Array[Node] = _editor_plugin.get_custom_selection()
	return gizmo.get_node_3d() in selected_nodes
