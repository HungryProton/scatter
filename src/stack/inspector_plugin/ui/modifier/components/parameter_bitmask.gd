@tool
extends "base_parameter.gd"


@onready var _label: Label = $Label
@onready var _grid_1: Control = $%GridContainer1
@onready var _grid_2: Control = $%GridContainer2
@onready var _grid_3: Control = $%GridContainer3
@onready var _grid_4: Control = $%GridContainer4
@onready var _menu_button: MenuButton = $%MenuButton

var _buttons: Array[Button]
var _popup: PopupMenu
var _layer_count := 32


func _ready() -> void:
	_buttons = []
	var grids = [_grid_1, _grid_2, _grid_3, _grid_4]

	for g in grids:
		for c in g.get_children():
			if c is Button:
				var layer_number = c.text.to_int()
				if layer_number > _layer_count:
					c.visible = false
					continue
				_buttons.push_front(c)
				c.focus_mode = Control.FOCUS_NONE
				c.pressed.connect(_on_button_pressed)

	_popup = _menu_button.get_popup()
	_popup.clear()

	var layer_name := ""
	for i in _layer_count:
		if i != 0 and i % 4 == 0:
			_popup.add_separator("", 100 + i)

		layer_name = ProjectSettings.get_setting("layer_names/3d_physics/layer_" + str(i + 1))
		if layer_name.is_empty():
			layer_name = "Layer " + str(i + 1)
		_popup.add_check_item(layer_name, _layer_count - 1 - i)

	_sync_popup_state()
	_popup.id_pressed.connect(_on_id_pressed)


func set_parameter_name(text: String) -> void:
	_label.text = text


func _set_value(val: int) -> void:
	var binary_string: String = _dec2bin(val)
	var length = binary_string.length()

	if length < _layer_count:
		binary_string = binary_string.pad_zeros(_layer_count)
	elif length > _layer_count:
		binary_string = binary_string.substr(length - _layer_count, length)

	for i in _layer_count:
		_buttons[i].button_pressed = binary_string[i] == "1"

	_sync_popup_state()


func get_value() -> int:
	var binary_string = ""
	for b in _buttons:
		binary_string += "1" if b.button_pressed else "0"

	var val = _bin2dec(binary_string)
	return val


func _dec2bin(value: int) -> String:
	if value == 0:
		return "0"

	var binary_string = ""
	while value != 0:
		var m = value % 2
		binary_string = str(m) + binary_string
		# warning-ignore:integer_division
		value = value / 2

	return binary_string


func _bin2dec(binary_string: String) -> int:
	var decimal_value = 0
	var count = binary_string.length() - 1

	for i in binary_string.length():
		decimal_value += pow(2, count) * binary_string[i].to_int()
		count -= 1

	return decimal_value


func _sync_popup_state() -> void:
	if not _popup:
		return

	for i in _layer_count:
		var idx = _popup.get_item_index(i)
		_popup.set_item_checked(idx, _buttons[i].button_pressed)


func _on_button_pressed() -> void:
	_on_value_changed(null)
	_sync_popup_state()


func _on_id_pressed(id: int) -> void:
	var idx = _popup.get_item_index(id)
	var checked = not _popup.is_item_checked(idx)
	_buttons[id].button_pressed = checked
	_popup.set_item_checked(idx, checked)
	_on_button_pressed()


func _on_enable_all_pressed() -> void:
	_set_value(4294967295)
	_on_value_changed(null)


func _on_clear_pressed() -> void:
	_set_value(0)
	_on_value_changed(null)
