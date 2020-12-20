tool
extends EditorPlugin


var modifier_stack_plugin: EditorInspectorPlugin = load(
	_get_current_folder() + 
	"/src/tools/modifier_stack_inspector_plugin/modifier_stack_plugin.gd").new()


func get_name():
	return "Scatter"


func _enter_tree():
	var root: String = _get_current_folder()
	add_inspector_plugin(modifier_stack_plugin)
	add_custom_type(
		"Scatter",
		"Path",
		load(root + "/src/core/scatter.gd"),
		load(root + "/icons/scatter.svg")
	)
	add_custom_type(
		"ScatterItem",
		"Spatial",
		load(root + "/src/core/scatter_item.gd"),
		load(root + "/icons/item.svg")
	)


func _exit_tree():
	remove_inspector_plugin(modifier_stack_plugin)
	remove_custom_type("Scatter")
	remove_custom_type("ScatterItem")


func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()
