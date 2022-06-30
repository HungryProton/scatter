# warning-ignore-all:return_value_discarded

@tool
extends "base_parameter.gd"


@onready var _label: Label = $Label
@onready var _x: SpinBox = $%X
@onready var _y: SpinBox = $%Y
@onready var _link: Button = $%LinkButton


func _ready() -> void:
	_x.value_changed.connect(_on_spinbox_value_changed)
	_y.value_changed.connect(_on_spinbox_value_changed)


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


func _on_spinbox_value_changed(value: float) -> void:
	if _link.button_pressed:
		var old = get_value()
		set_value(Vector2(value, value))
		_previous = old

	_on_value_changed(get_value())
