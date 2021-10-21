# warning-ignore-all:return_value_discarded

tool
extends "base_parameter.gd"


onready var _label: Label = $Label
onready var _x: SpinBox = $MarginContainer/MarginContainer/HBoxContainer/GridContainer/HBoxContainer/X
onready var _y: SpinBox = $MarginContainer/MarginContainer/HBoxContainer/GridContainer/HBoxContainer2/Y


func _ready() -> void:
	_x.connect("value_changed", self, "_on_value_changed")
	_y.connect("value_changed", self, "_on_value_changed")


func set_parameter_name(text: String) -> void:
	_label.text = text


func get_value() -> Vector2:
	var vec2 = Vector2.ZERO
	vec2.x = _x.get_value()
	vec2.y = _y.get_value()
	return vec2


func _set_value(val: Vector2) -> void:
	_x.set_value(val.x)
	_y.set_value(val.y)


func _on_clear_pressed():
	var old = get_value()
	set_value(Vector2.ZERO)
	_previous = old
	_on_value_changed(Vector2.ZERO)
