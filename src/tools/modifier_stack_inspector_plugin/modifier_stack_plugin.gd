extends EditorInspectorPlugin

# Displays a control panel in the inspector to monitor the connection status
# with the standalone app and let the user manually force the generation if
# needed.


var _root := _get_root_folder()
var _namespace = load(_root + "/src/core/namespace.gd").new()
var _editor = load(_root + "/src/tools/modifier_stack_inspector_plugin/editor_property.gd")


func can_handle(object):
	return object is _namespace.Scatter


func parse_property(object, type, path, _hint, hint_text, _usage):
	if type == TYPE_OBJECT and hint_text == "ScatterModifierStack":
		var editor_property = _editor.new()
		editor_property.set_node(object)
		add_property_editor(path, editor_property)
		return true
	return false


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]
