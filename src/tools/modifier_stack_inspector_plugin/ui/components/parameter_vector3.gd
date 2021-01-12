tool
extends "base_parameter.gd"


onready var _label: Label = $Label
onready var _x: SpinBox = $MarginContainer/MarginContainer/HBoxContainer/GridContainer/HBoxContainer/X
onready var _y: SpinBox = $MarginContainer/MarginContainer/HBoxContainer/GridContainer/HBoxContainer2/Y
onready var _z: SpinBox = $MarginContainer/MarginContainer/HBoxContainer/GridContainer/HBoxContainer3/Z


func _ready() -> void:
	_x.connect("value_changed", self, "_on_value_changed")
	_y.connect("value_changed", self, "_on_value_changed")
	_z.connect("value_changed", self, "_on_value_changed")


func set_parameter_name(text: String) -> void:
	_label.text = text


func get_value() -> Vector3:
	var vec3 = Vector3.ZERO
	vec3.x = _x.get_value()
	vec3.y = _y.get_value()
	vec3.z = _z.get_value()
	return vec3


func _set_value(val: Vector3) -> void:
	_x.set_value(val.x)
	_y.set_value(val.y)
	_z.set_value(val.z)


func _on_clear_pressed():
	var old = get_value()
	set_value(Vector3.ZERO)
	_previous = old
	_on_value_changed(Vector3.ZERO)
