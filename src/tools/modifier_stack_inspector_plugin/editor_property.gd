extends EditorProperty


var _ui: Control


func _init():
	_ui = preload("./ui/stack_panel.tscn").instance()
	add_child(_ui)
	set_bottom_editor(_ui)


func set_node(object) -> void:
	_ui.set_node(object)
