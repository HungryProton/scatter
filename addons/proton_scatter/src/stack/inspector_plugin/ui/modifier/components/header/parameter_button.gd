@tool
extends "../base_parameter.gd"


var _button


func _ready() -> void:
	_button = get_node("Button")
	_button.toggled.connect(_on_value_changed)


func enable(enabled: bool) -> void:
	_button.disabled = not enabled
	_button.flat = not enabled


func get_value() -> bool:
	return _button.button_pressed


func _set_value(val: bool) -> void:
	_button.button_pressed = val
