tool
extends MenuButton

signal add_modifier


var _popup: PopupMenu
var _modifiers := []
var _default_icon = load(_get_root_folder() + "/icons/item.svg")


func _ready() -> void:
	_modifiers = _find_all_modifiers(_get_root_folder() + "/src/modifiers/")
	_popup = get_popup()
	_popup.clear()
	_popup.connect("id_pressed", self, "_on_id_pressed")
	
	for i in _modifiers.size():
		var modifier = _modifiers[i].new()
		_popup.add_icon_item(_default_icon, modifier.display_name, i)
		modifier.queue_free()


func _find_all_modifiers(path: String) -> Array:
	var list := []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	var path_root = dir.get_current_dir() + "/"

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if dir.current_is_dir():
			list += _find_all_modifiers(path_root + file)
			continue
		if not file.ends_with(".gd") and not file.ends_with(".gdc"):
			continue

		var full_path = path_root + file
		var script = load(full_path)
		if not script or not script.can_instance():
			print("Error: Failed to load script ", file)
			continue

		list.push_back(script)

	dir.list_dir_end()
	return list


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_id_pressed(id) -> void:
	if id < _modifiers.size():
		emit_signal("add_modifier", _modifiers[id].new())
