@tool
extends "base_parameter.gd"


@onready var _label: Label = $Label
@onready var _x: SpinBox = $%X
@onready var _y: SpinBox = $%Y
@onready var _z: SpinBox = $%Z
@onready var _link: Button = $%LinkButton


func _ready() -> void:
	_x.value_changed.connect(_on_spinbox_value_changed)
	_y.value_changed.connect(_on_spinbox_value_changed)
	_z.value_changed.connect(_on_spinbox_value_changed)


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


func _on_spinbox_value_changed(value: float) -> void:
	if _link.button_pressed:
		var old = get_value()
		set_value(Vector3(value, value, value))
		_previous = old

	_on_value_changed(get_value())
