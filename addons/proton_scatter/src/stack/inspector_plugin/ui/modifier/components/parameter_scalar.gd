# warning-ignore-all:return_value_discarded

@tool
extends "base_parameter.gd"


var _is_int := false
var _is_enum := false

@onready var _label: Label = $Label
@onready var _spinbox: SpinBox = $%SpinBox
@onready var _option: OptionButton = $%OptionButton


func _ready() -> void:
	_spinbox.value_changed.connect(_on_value_changed)
	_option.item_selected.connect(_on_value_changed)
	mark_as_int(_is_int)


func mark_as_int(val: bool) -> void:
	_is_int = val
	if _is_int and _spinbox:
		_spinbox.step = 1


func mark_as_enum(val: bool) -> void:
	_is_enum = val


func toggle_option_item(idx: int, value := false) -> void:
	_option.set_item_disabled(idx, not value)


func set_parameter_name(text: String) -> void:
	_label.text = text


func set_hint_string(hint: String) -> void:
	# No hint provided, ignore.
	if hint.is_empty():
		return

	if hint == "float":
		_spinbox.step = 0.01
		return

	if hint == "int":
		_spinbox.step = 1
		return

	# One integer provided
	if hint.is_valid_int():
		_set_range(0, hint.to_int())
		return

	# Multiple items provided, check their types
	var tokens = hint.split(",")
	var all_int = true
	var all_float = true

	for t in tokens:
		if not t.is_valid_int():
			all_int = false
		if not t.is_valid_float():
			all_float = false

	# All items are integer
	if all_int and tokens.size() >= 2:
		_set_range(tokens[0].to_int(), tokens[1].to_int())
		return

	# All items are float
	if all_float:
		if tokens.size() >= 2:
			_set_range(tokens[0].to_float(), tokens[1].to_float())
		if tokens.size() >= 3:
			_spinbox.step = tokens[2].to_float()
		return

	# All items are strings, make it a dropdown
	_spinbox.visible = false
	_option.visible = true
	_is_enum = true
	_is_int = true

	for i in tokens.size():
		_option.add_item(_sanitize_option_name(tokens[i]), i)

	set_value(int(_spinbox.get_value()))


func get_value():
	if _is_enum:
		return _option.get_selected_id()
	if _is_int:
		return int(_spinbox.get_value())
	return _spinbox.get_value()


func _set_value(val) -> void:
	if _is_int:
		val = int(val)
	if _is_enum:
		_option.select(val)
	else:
		_spinbox.set_value(val)


func _set_range(start, end) -> void:
	if start < end:
		_spinbox.min_value = start
		_spinbox.max_value = end
		_spinbox.allow_greater = false
		_spinbox.allow_lesser = false


func _sanitize_option_name(token: String) -> String:
	return token.left(token.find(":"))
