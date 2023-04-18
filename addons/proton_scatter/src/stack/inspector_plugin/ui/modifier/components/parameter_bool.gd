@tool
extends "base_parameter.gd"


@onready var _label: Label = $Label
@onready var _check_box: CheckBox = $CheckBox


func _ready() -> void:
	# warning-ignore:return_value_discarded
	_check_box.connect("toggled", _on_value_changed)


func set_parameter_name(text: String) -> void:
	_label.text = text


func get_value() -> bool:
	return _check_box.button_pressed


func _set_value(val: bool) -> void:
	_check_box.button_pressed = val
