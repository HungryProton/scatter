tool
extends "base_parameter.gd"


onready var _label: Label = $Label
onready var _select_button: Button = $HBoxContainer/FileButton
onready var _dialog: FileDialog = $Control/FileDialog

var _path := ""


func _ready() -> void:
	pass


func set_parameter_name(text: String) -> void:
	_label.text = text


func _set_value(val: String) -> void:
	_path = val
	_select_button.text = val.get_file()

	if val.empty():
		_select_button.text = "Select a file"


func get_value() -> String:
	return _path


func _on_clear_button_pressed() -> void:
	_set_value("")
	_on_value_changed("")


func _on_select_button_pressed() -> void:
	_dialog.popup_centered()


func _on_file_selected(file: String) -> void:
	_set_value(file)
	_on_value_changed(file)
