tool
extends "base_parameter.gd"


onready var _label: Label = $Label
onready var _line_edit: LineEdit = $MarginContainer/MarginContainer/LineEdit


func _ready() -> void:
	_line_edit.connect("text_entered", self, "_on_value_changed")
	_line_edit.connect("focus_exited", self, "_on_focus_exited")


func set_parameter_name(text: String) -> void:
	_label.text = text


func _set_value(val: String) -> void:
	_line_edit.text = val


func get_value() -> String:
	return _line_edit.get_text()


func _on_focus_exited() -> void:
	_on_value_changed(get_value())
