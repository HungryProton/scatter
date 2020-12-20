tool
extends HBoxContainer


signal value_changed


var _is_int := false

onready var _label: Label = $Label
onready var _check_box: CheckBox = $CheckBox


func _ready() -> void:
	_check_box.connect("toggled", self, "_on_value_changed")


func set_parameter_name(text: String) -> void:
	_label.text = text


func set_value(val: bool) -> void:
	_check_box.pressed = val


func get_value() -> bool:
	return _check_box.pressed


func _on_value_changed(value) -> void:
	emit_signal("value_changed", value)
