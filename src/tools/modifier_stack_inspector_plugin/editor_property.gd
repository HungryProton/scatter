extends EditorProperty


var _ui: Control


func _init():
	_ui = load(_get_current_folder() + "/ui/stack_panel.tscn").instance()
	add_child(_ui) 
	set_bottom_editor(_ui)


func set_node(object) -> void:
	_ui.set_node(object)


func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()
