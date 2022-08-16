tool
extends EditorPlugin


const Util = preload("src/util.gd")
const ScatterPath = preload("./src/core/scatter_path.gd")
const Scatter = preload("./src/core/scatter.gd")

var _modifier_stack_plugin: EditorInspectorPlugin = preload("./src/tools/modifier_stack_inspector_plugin/modifier_stack_plugin.gd").new()
var _scatter_path_gizmo_plugin: EditorSpatialGizmoPlugin = preload("./src/tools/path_gizmo/scatter_path_gizmo_plugin.gd").new()
var _point_gizmo_plugin: EditorSpatialGizmoPlugin = preload("./src/tools/point_gizmo/point_gizmo_plugin.gd").new()
var _editor_selection
var _gizmo_options: Control
var _options_root: Control


func get_name():
	return "Scatter"


func _enter_tree():
	add_inspector_plugin(_modifier_stack_plugin)
	add_custom_type(
		"Scatter",
		"Path",
		preload("./src/core/scatter.gd"),
		preload("./icons/scatter.svg")
	)
	add_custom_type(
		"ScatterItem",
		"Spatial",
		preload("./src/core/scatter_item.gd"),
		preload("./icons/item.svg")
	)
	add_custom_type(
		"ScatterExcludePath",
		"Path",
		preload("./src/core/scatter_exclude_path.gd"),
		preload("./icons/exclude_path.svg")
	)
	add_custom_type(
		"ScatterPoint",
		"Spatial",
		preload("./src/core/scatter_exclude_point.gd"),
		preload("./icons/point.svg")
	)
	add_custom_type(
		"ScatterUpdateGroup",
		"Spatial",
		preload("./src/core/update_group.gd"),
		preload("./icons/group.svg")
	)

	set_input_event_forwarding_always_enabled()
	_setup_options_panel()

	_scatter_path_gizmo_plugin.editor_plugin = self
	_scatter_path_gizmo_plugin.options = _gizmo_options
	add_spatial_gizmo_plugin(_scatter_path_gizmo_plugin)
	add_spatial_gizmo_plugin(_point_gizmo_plugin)

	_editor_selection = get_editor_interface().get_selection()
	_editor_selection.connect("selection_changed", self, "_on_selection_changed")

	# warning-ignore:return_value_discarded
	connect("scene_changed", self, "_on_scene_changed")


func _exit_tree():
	remove_inspector_plugin(_modifier_stack_plugin)
	remove_custom_type("Scatter")
	remove_custom_type("ScatterItem")
	remove_custom_type("ScatterExcludePath")
	remove_custom_type("ScatterPoint")
	remove_custom_type("ScatterUpdateGroup")
	remove_spatial_gizmo_plugin(_scatter_path_gizmo_plugin)
	remove_spatial_gizmo_plugin(_point_gizmo_plugin)
	_gizmo_options.queue_free()


func forward_spatial_gui_input(camera: Camera, _event: InputEvent) -> bool:
	if _scatter_path_gizmo_plugin:
		_scatter_path_gizmo_plugin.set_editor_camera(camera)

	return false


func _on_selection_changed() -> void:
	var selected = _editor_selection.get_selected_nodes()

	if selected.empty() or not selected[0] is ScatterPath:
		_hide_options_panel()
		_scatter_path_gizmo_plugin.set_selected(null)
	else:
		_show_options_panel()
		_scatter_path_gizmo_plugin.set_selected(selected[0])

		if selected[0] is Scatter:
			selected[0].undo_redo = get_undo_redo()

		if _gizmo_options.snap_to_colliders():
			_on_snap_to_colliders_enabled()


func _on_scene_changed(_root) -> void:
	var selected = _editor_selection.get_selected_nodes()
	if selected.empty():
		_hide_options_panel()
		_scatter_path_gizmo_plugin.set_selected(null)


func _show_options_panel():
	_gizmo_options.visible = true


func _hide_options_panel():
	_gizmo_options.visible = false


func _reset_all_colliders(node) -> void:
	if ProjectSettings.get_setting("physics/3d/physics_engine") == "GodotPhysics":
		# This workaround breaks things in godot physics, skip it
		return
	if node is CollisionShape and not node.disabled:
		node.disabled = true
		node.disabled = false

	for c in node.get_children():
		_reset_all_colliders(c)


func _setup_options_panel() -> void:
	var editor_viewport: VBoxContainer = get_editor_interface().get_editor_viewport()

	#slow, easy cause of future issues
	var descendants := get_child_recursive(editor_viewport)
	var spatial_viewport
	for child in descendants:
		if child.get_class() == "SpatialEditorViewport":
			spatial_viewport = child
			break

	_options_root = Util.get_node_by_class_path(spatial_viewport, [
		'Control',
		'VBoxContainer',
		])

	_gizmo_options = preload("./src/tools/path_gizmo/gizmo_options.tscn").instance()
	_options_root.add_child(_gizmo_options)

	# warning-ignore:return_value_discarded
	_gizmo_options.connect("snap_to_colliders_enabled", self, "_on_snap_to_colliders_enabled")
	_gizmo_options.visible = false


func _on_snap_to_colliders_enabled():
	var selected = _editor_selection.get_selected_nodes()
	if not selected.empty():
		var root = selected[0].get_tree().root
		_reset_all_colliders(root)

#from https://github.com/addmix/godot_utils nodeutils.gd
static func get_child_recursive(obj : Node) -> Array:
	var children : Array = obj.get_children()

	#array for storing all descendants
	var arr := []

	for i in range(children.size()):
		arr.append(children[i])
		#add child's array contents to self's array
		arr += get_child_recursive(children[i])

	return arr
