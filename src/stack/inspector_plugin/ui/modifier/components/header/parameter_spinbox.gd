@tool
extends "../base_parameter.gd"


@onready var _spinbox = $SpinBox


func _ready() -> void:
	_spinbox.value_changed.connect(_on_value_changed)


func get_value() -> int:
	return int(_spinbox.get_value())


func _set_value(val: int) -> void:
	_spinbox.set_value(val)
