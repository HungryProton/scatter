tool
extends EditorPlugin

# /!\ This plugin depends on the PolygonPath plugin. They must be both active for
# this plugin to work

# --
# EditorPlugin overrides
# --

func get_name():
	return "Scatter"

func _enter_tree():
	add_custom_type(
		"ScatterDuplicates",
		"PolygonPath",
		load("res://addons/scatter/src/nodes/scatter_duplicates.gd"),
		load("res://addons/scatter/icons/duplicates.svg")
	)
	add_custom_type(
		"ScatterMultiMesh",
		"PolygonPath",
		load("res://addons/scatter/src/nodes/scatter_multi_mesh.gd"),
		load("res://addons/scatter/icons/multimesh.svg")
	)
	add_custom_type(
		"ScatterItem",
		"Spatial",
		load("res://addons/scatter/src/nodes/scatter_item.gd"),
		load("res://addons/scatter/icons/item.svg")
	)
	add_custom_type(
		"ScatterExclude",
		"PolygonPath",
		load("res://addons/scatter/src/nodes/scatter_exclude.gd"),
		load("res://addons/scatter/icons/item.svg")
	)


func _exit_tree():
	remove_custom_type("ScatterDuplicates")
	remove_custom_type("ScatterMultimesh")
	remove_custom_type("ScatterItem")

# --
# Internal methods
# --
