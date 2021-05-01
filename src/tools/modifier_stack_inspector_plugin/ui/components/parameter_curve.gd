tool
extends "base_parameter.gd"


const Util = preload("../../../../common/util.gd")


onready var _label: Label = $Label
onready var _panel: Control = $MarginContainer/CurvePanel


func set_parameter_name(text: String) -> void:
	_label.text = text


func get_value() -> String:
	return Util.curve_to_string(_panel.get_curve())


func _set_value(val: String) -> void:
	var curve = Util.string_to_curve(val)
	_panel.set_curve(curve)


func _on_curve_updated() -> void:
	_on_value_changed(get_value())
