tool
extends "base_parameter.gd"


onready var _label: Label = $Label
onready var _check_box: CheckBox = $CheckBox


func _ready() -> void:
	_check_box.connect("toggled", self, "_on_value_changed")


func set_parameter_name(text: String) -> void:
	_label.text = text


func get_value() -> bool:
	return _check_box.pressed


func _set_value(val: bool) -> void:
	_check_box.pressed = val
