@tool
extends Window


signal save_preset


@onready var _line_edit: LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var _cancel: Button = $MarginContainer/VBoxContainer/HBoxContainer/Cancel
@onready var _save: Button = $MarginContainer/VBoxContainer/HBoxContainer/Save
@onready var _warning: Label = $MarginContainer/VBoxContainer/Warning
@onready var _confirm_overwrite = $ConfirmationDialog


func _ready():
	_cancel.pressed.connect(_on_cancel_pressed)
	_save.pressed.connect(_on_save_pressed)
	_warning.text = ""
	_confirm_overwrite.confirmed.connect(_save_preset)


func _on_cancel_pressed() -> void:
	visible = false
	_line_edit.text = ""


func _on_save_pressed() -> void:
	var preset_name: String = _line_edit.text
	if preset_name.is_empty():
		_warning.text = "Preset name can't be empty"
		return

	if not preset_name.is_valid_filename():
		_warning.text = """Preset name must be a valid file name.
			It cannot contain the following characters:
			: / \\ ? * " | % < >"""
		return

	_warning.text = ""
	if _exists(preset_name):
		_confirm_overwrite.dialog_text = "Preset \"" + preset_name + "\" already exists. Overwrite?"
		_confirm_overwrite.popup_centered()
	else:
		_save_preset()


func _save_preset() -> void:
	emit_signal("save_preset", _line_edit.text)
	visible = false
	_line_edit.text = ""


func _exists(preset: String) -> bool:
	var dir = DirAccess.open(_get_root_folder() + "/presets/")
	if not dir:
		return false

	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break

		if file == preset + ".tscn":
			dir.list_dir_end()
			return true

	dir.list_dir_end()
	return false


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]
