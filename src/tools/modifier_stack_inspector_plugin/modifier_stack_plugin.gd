@tool
extends EditorInspectorPlugin

# Displays a control panel in the inspector to monitor the connection status
# with the standalone app and let the user manually force the generation if
# needed.


const Scatter = preload("../../core/namespace.gd")
const Editor = preload("../modifier_stack_inspector_plugin/editor_property.gd")


func can_handle(object):
	return object is Scatter.Scatter


func parse_property(object, type, path, _hint, hint_text, _usage):
	if type == TYPE_OBJECT and hint_text == "ScatterModifierStack":
		var editor_property = Editor.new()
		editor_property.set_node(object)
		add_property_editor(path, editor_property)
		return true
	return false
