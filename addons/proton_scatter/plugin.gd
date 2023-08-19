@tool
extends EditorPlugin


const ProtonScatter := preload("./src/scatter.gd")
const ProtonScatterShape := preload("./src/scatter_shape.gd")
const ModifierStackPlugin := preload("./src/stack/inspector_plugin/modifier_stack_plugin.gd")
const ScatterGizmoPlugin := preload("./src/scatter_gizmo_plugin.gd")
const ShapeGizmoPlugin := preload("./src/shapes/gizmos_plugin/shape_gizmo_plugin.gd")
const PathPanel := preload("./src/shapes/gizmos_plugin/components/path_panel.tscn")
const ScatterCachePlugin := preload("./src/cache/inspector_plugin/scatter_cache_plugin.gd")

const GIZMO_SETTING := "addons/proton_scatter/always_show_gizmos"
const MAX_PHYSICS_QUERIES_SETTING := "addons/proton_scatter/max_physics_queries_per_frame"

var _modifier_stack_plugin := ModifierStackPlugin.new()
var _scatter_gizmo_plugin := ScatterGizmoPlugin.new()
var _shape_gizmo_plugin := ShapeGizmoPlugin.new()
var _scatter_cache_plugin := ScatterCachePlugin.new()
var _path_panel
var _selected_scatter_group: Array[Node] = []


func _get_plugin_name():
	return "ProtonScatter"


func _enter_tree():
	_ensure_setting_exists(GIZMO_SETTING, true)
	_ensure_setting_exists(MAX_PHYSICS_QUERIES_SETTING, 500)

	add_inspector_plugin(_modifier_stack_plugin)
	add_inspector_plugin(_scatter_cache_plugin)

	_path_panel = PathPanel.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _path_panel)
	_path_panel.visible = false

	add_node_3d_gizmo_plugin(_scatter_gizmo_plugin)
	_scatter_gizmo_plugin.set_editor_plugin(self)

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


func get_custom_selection() -> Array[Node]:
	return _selected_scatter_group


func _refresh_scatter_gizmos(nodes: Array[Node]) -> void:
	for node in nodes:
		if not is_instance_valid(node):
			continue

		if node is ProtonScatterShape:
			_refresh_scatter_gizmos([node.get_parent()])
			continue

		if node is ProtonScatter:
			node.update_gizmos()
			for c in node.get_children():
				if c is Node3D:
					c.update_gizmos()


func _ensure_setting_exists(setting: String, default_value) -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, default_value)
		ProjectSettings.set_initial_value(setting, default_value)

		if ProjectSettings.has_method("set_as_basic"): # 4.0 backward compatibility
			ProjectSettings.call("set_as_basic", setting, true)


func _on_selection_changed() -> void:
	# Clean the gizmos on the previous node selection
	_refresh_scatter_gizmos(_selected_scatter_group)
	_selected_scatter_group.clear()

	# Get the currently selected nodes
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	_path_panel.selection_changed(selected)

	if selected.is_empty():
		return

	# Update the selected local scatter group.
	# If the user selects a shape, the scatter group will contain the ScatterShape,
	# all the sibling shapes, and the parent scatter node, even if they are not
	# selected. This is required to make their gizmos appear.
	for node in selected:
		var scatter_node

		if node is ProtonScatter:
			scatter_node = node

		elif node is ProtonScatterShape and is_instance_valid(node):
			scatter_node = node.get_parent()

		if not is_instance_valid(scatter_node):
			continue

		_selected_scatter_group.push_back(scatter_node)
		scatter_node.undo_redo = get_undo_redo()
		scatter_node.editor_plugin = self

		for c in scatter_node.get_children():
			if c is ProtonScatterShape:
				_selected_scatter_group.push_back(c)

	_refresh_scatter_gizmos(_selected_scatter_group)


func _on_scene_changed(_scene_root) -> void:
	pass
