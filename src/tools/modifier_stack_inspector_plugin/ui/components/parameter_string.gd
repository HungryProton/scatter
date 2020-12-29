tool
extends HBoxContainer


signal value_changed


var _locked := false
var _previous: String

onready var _label: Label = $Label
onready var _line_edit: LineEdit = $MarginContainer/MarginContainer/LineEdit


func _ready() -> void:
	_line_edit.connect("text_entered", self, "_on_value_changed")
	_line_edit.connect("focus_exited", self, "_on_focus_exited")


func set_parameter_name(text: String) -> void:
	_label.text = text


func set_value(val: String) -> void:
	_locked = true
	_line_edit.text = val
	_previous = get_value()
	_locked = false


func get_value() -> String:
	return _line_edit.get_text()


func _on_value_changed(value) -> void:
	if not _locked:
		if value != _previous:
			emit_signal("value_changed", value, _previous)


func _on_focus_exited() -> void:
	_on_value_changed(get_value())
