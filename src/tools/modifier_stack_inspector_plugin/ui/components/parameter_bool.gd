tool
extends HBoxContainer


signal value_changed


var _previous: bool
var _locked := false

onready var _label: Label = $Label
onready var _check_box: CheckBox = $CheckBox


func _ready() -> void:
	_check_box.connect("toggled", self, "_on_value_changed")


func set_parameter_name(text: String) -> void:
	_label.text = text


func set_value(val: bool) -> void:
	_locked = true
	_check_box.pressed = val
	_previous = get_value()
	_locked = false


func get_value() -> bool:
	return _check_box.pressed


func _on_value_changed(value) -> void:
	if not _locked:
		emit_signal("value_changed", value, _previous)
