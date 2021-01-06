tool
extends EditorPlugin


var _modifier_stack_plugin: EditorInspectorPlugin = preload("./src/tools/modifier_stack_inspector_plugin/modifier_stack_plugin.gd").new()
var _scatter_path_gizmo_plugin: EditorSpatialGizmoPlugin = preload("./src/tools/path_gizmo/scatter_path_gizmo_plugin.gd").new()
var _editor_selection
var _gizmo_options: Control = preload("./src/tools/path_gizmo/gizmo_options.tscn").instance()
var _scatter_path = preload("./src/core/scatter_path.gd")

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
		preload("./icons/exclude.svg")
	)
	add_custom_type(
		"ScatterExcludePoint",
		"Spatial",
		preload("./src/core/scatter_exclude_point.gd"),
		preload("./icons/exclude.svg")
	)
	
	_scatter_path_gizmo_plugin.editor_plugin = self
	_scatter_path_gizmo_plugin.options = _gizmo_options
	add_spatial_gizmo_plugin(_scatter_path_gizmo_plugin)
	_gizmo_options.connect("snap_to_colliders_enabled", self, "_on_snap_to_colliders_enabled")
	
	_editor_selection = get_editor_interface().get_selection()
	_editor_selection.connect("selection_changed", self, "_on_selection_changed")
	connect("scene_changed", self, "_on_scene_changed")


func _exit_tree():
	remove_inspector_plugin(_modifier_stack_plugin)
	remove_custom_type("Scatter")
	remove_custom_type("ScatterItem")
	remove_custom_type("ScatterExcludePath")
	remove_custom_type("ScatterExcludePoint")
	_hide_options_panel()
	remove_spatial_gizmo_plugin(_scatter_path_gizmo_plugin)


func _on_selection_changed() -> void:
	var selected = _editor_selection.get_selected_nodes()
	
	if selected.empty():
		# Node was deselected but nothing else was selected. By default, Godot
		# will keep the path editor panel on top so we do the same.
		return 
	
	if selected[0] is _scatter_path:
		_show_options_panel()
		_scatter_path_gizmo_plugin.set_selection(selected[0])
		selected[0].undo_redo = get_undo_redo()
		
		if _gizmo_options.snap_to_colliders():
			_on_snap_to_colliders_enabled()
	else:
		_hide_options_panel()
		_scatter_path_gizmo_plugin.set_selection(null)


func _on_scene_changed(_root) -> void:
	var selected = _editor_selection.get_selected_nodes()
	if selected.empty():
		_hide_options_panel()
		_scatter_path_gizmo_plugin.set_selection(null)


func _show_options_panel():
	if not _gizmo_options.get_parent():
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _gizmo_options)


func _hide_options_panel():
	if _gizmo_options.get_parent():
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _gizmo_options)


func _on_snap_to_colliders_enabled():
	var selected = _editor_selection.get_selected_nodes()
	if not selected.empty():
		var root = selected[0].get_tree().root
		_reset_all_colliders(root)


func _reset_all_colliders(node) -> void:
	if node is CollisionShape and not node.disabled:
		node.disabled = true
		node.disabled = false
	
	for c in node.get_children():
		_reset_all_colliders(c)
