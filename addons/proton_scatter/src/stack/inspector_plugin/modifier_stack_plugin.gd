@tool
extends EditorInspectorPlugin


const Editor = preload("./editor_property.gd")
const Scatter = preload("../../scatter.gd")


func _can_handle(object):
	return is_instance_of(object, Scatter)


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "modifier_stack":
		var editor_property = Editor.new()
		editor_property.set_node(object)
		add_property_editor("modifier_stack", editor_property)
		return true
	return false
