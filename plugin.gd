@tool
extends EditorPlugin


var _modifier_stack_plugin: EditorInspectorPlugin = preload("./src/stack/inspector_plugin/modifier_stack_plugin.gd").new()
var _shape_gizmo_plugin: EditorNode3DGizmoPlugin = preload("./src/shapes/gizmos_plugin/shape_gizmo_plugin.gd").new()


func get_name():
	return "ProtonScatter"


func _enter_tree():
	add_inspector_plugin(_modifier_stack_plugin)
	add_spatial_gizmo_plugin(_shape_gizmo_plugin)

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

func _exit_tree():
	remove_custom_type("ProtonScatter")
	remove_custom_type("ScatterItem")
	remove_custom_type("ScatterShape")
	remove_inspector_plugin(_modifier_stack_plugin)
	remove_spatial_gizmo_plugin(_shape_gizmo_plugin)
