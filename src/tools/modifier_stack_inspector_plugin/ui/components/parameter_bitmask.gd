tool
extends "base_parameter.gd"


onready var _label: Label = $Label
onready var _root: Control = $MarginContainer/HBoxContainer/GridContainer

var _buttons: Array


func _ready() -> void:
	for c in _root.get_children():
		if c is Button:
			_buttons.push_front(c)
			c.connect("pressed", self, "_on_button_pressed")


func set_parameter_name(text: String) -> void:
	_label.text = text


func _set_value(val: String) -> void:
	var binary_string: String = dec2bin(int(val))
	var length = binary_string.length()
	binary_string = binary_string.substr(length - 20, length)
	for i in 20:
		_buttons[i].pressed = binary_string[i] == "1"


func get_value() -> String:
	var binary_string = ""
	for b in _buttons:
		binary_string += "1" if b.pressed else "0"

	var val = bin2dec(binary_string)
	return String(val)


func dec2bin(var value: int) -> String:
	var binary_string = ""

	while value != 0:
		var m = value % 2
		binary_string = String(m) + binary_string
		value = value / 2

	return binary_string


func bin2dec(var binary_string: String) -> int:
	var decimal_value = 0
	var count = binary_string.length() - 1

	for i in binary_string.length():
		decimal_value += pow(2, count) * int(binary_string[i])
		count -= 1

	return decimal_value


func _on_button_pressed() -> void:
	_on_value_changed(get_value())
