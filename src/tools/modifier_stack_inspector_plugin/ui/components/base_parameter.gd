tool
extends Control


signal value_changed

var _previous
var _locked := false


func set_parameter_name(_text: String) -> void:
	pass


func set_hint_string(_hint: String) -> void:
	pass


func set_value(val) -> void:
	_locked = true
	_set_value(val)
	_previous = get_value()
	_locked = false


func get_value():
	pass


func _set_value(_val):
	pass


func _on_value_changed(_val) -> void:
	if not _locked:
		var value = get_value()
		if value != _previous:
			emit_signal("value_changed", value, _previous)
