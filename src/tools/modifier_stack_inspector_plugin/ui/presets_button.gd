tool
extends MenuButton


var _popup: PopupMenu
var _save_icon = load(_get_root_folder() + "/icons/save.svg")
var _load_icon = load(_get_root_folder() + "/icons/load.svg")
var _load_popup: WindowDialog
var _save_popup: WindowDialog


func _ready() -> void:
	_popup = get_popup()
	_popup.clear()

	# warning-ignore:return_value_discarded
	_popup.connect("id_pressed", self, "_on_id_pressed")

	_popup.add_icon_item(_save_icon, "Save Preset", 0)
	_popup.add_icon_item(_load_icon, "Load Preset", 1)

	_load_popup = get_node("LoadPresetPopup")
	_save_popup = get_node("SavePresetPopup")


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_id_pressed(id) -> void:
	match id:
		0:
			_save_popup.popup_centered()
		1:
			_load_popup.popup_centered()
