@tool
extends MenuButton


var _popup: PopupMenu
var _save_icon = preload("../../../../icons/save.svg")
var _load_icon = preload("../../../../icons/load.svg")
var _load_popup: FileDialog
var _save_popup: FileDialog


func _ready() -> void:
	_popup = get_popup()
	_popup.clear()

	# warning-ignore:return_value_discarded
	_popup.connect("id_pressed", _on_id_pressed)

	_popup.add_icon_item(_save_icon, "Save Preset", 0)
	_popup.add_icon_item(_load_icon, "Load Preset", 1)

	_load_popup = get_node("LoadPresetPopup")
	_save_popup = get_node("SavePresetPopup")


func _on_id_pressed(id) -> void:
	match id:
		0:
			_save_popup.popup_centered()
		1:
			_load_popup.popup_centered()
