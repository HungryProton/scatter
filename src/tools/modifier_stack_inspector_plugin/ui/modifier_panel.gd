tool
extends Control


signal move_up
signal move_down
signal remove_modifier
signal value_changed


var _scatter
var _modifier

onready var _parameters: Control = $MarginContainer/VBoxContainer/Parameters
onready var _name: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label
onready var _margin_container: MarginContainer = $MarginContainer
onready var _edit_buttons: Control = $MarginContainer/VBoxContainer/HBoxContainer/Buttons/EditButtons
onready var _enabled: Button = $MarginContainer/VBoxContainer/HBoxContainer/Buttons/HBoxContainer/Enable
onready var _warning: Button = $MarginContainer/VBoxContainer/HBoxContainer/Buttons/HBoxContainer/Warning
onready var _warning_popup: AcceptDialog = $AcceptDialog


func _ready() -> void:
	# warning-ignore:return_value_discarded
	_margin_container.connect("resized", self, "_on_child_resized")


func set_root(val) -> void:
	_scatter = val


func create_ui_for(modifier) -> void:
	_modifier = modifier
	_modifier.connect("warning_changed", self, "_on_warning_changed")
	_on_warning_changed()

	_name.text = modifier.display_name
	_enabled.pressed = modifier.enabled

	for property in modifier.get_property_list():
		if property.usage != PROPERTY_USAGE_DEFAULT + PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue

		if property.name == "enabled":
			continue

		var parameter_ui
		match property.type:
			TYPE_BOOL:
				parameter_ui = preload("./components/parameter_bool.tscn").instance()
			TYPE_REAL:
				parameter_ui = preload("./components/parameter_scalar.tscn").instance()
			TYPE_INT:
				parameter_ui = preload("./components/parameter_scalar.tscn").instance()
				parameter_ui.mark_as_int(true)
			TYPE_STRING:
				if property.hint_string == "Node":
					parameter_ui = preload("./components/parameter_node_selector.tscn").instance()
					parameter_ui.set_root(_scatter)
				elif property.hint_string == "File" or property.hint_string == "Texture":
					parameter_ui = preload("./components/parameter_file.tscn").instance()
				elif property.hint_string == "Curve":
					parameter_ui = preload("./components/parameter_curve.tscn").instance()
				elif property.hint_string == "bitmask":
					parameter_ui = preload("./components/parameter_bitmask.tscn").instance()
				else:
					parameter_ui = preload("./components/parameter_string.tscn").instance()
			TYPE_VECTOR3:
				parameter_ui = preload("./components/parameter_vector3.tscn").instance()
			TYPE_VECTOR2:
				parameter_ui = preload("./components/parameter_vector2.tscn").instance()


		if parameter_ui:
			_parameters.add_child(parameter_ui)
			parameter_ui.set_parameter_name(property.name.capitalize())
			parameter_ui.set_value(modifier.get(property.name))
			parameter_ui.set_hint_string(property.hint_string)
			parameter_ui.connect("value_changed", self, "_on_parameter_value_changed", [property.name, parameter_ui])


func _restore_value(name, val, ui) -> void:
	_modifier.set(name, val)
	ui.set_value(val)
	emit_signal("value_changed")


func _on_expand_toggled(toggled: bool) -> void:
	_parameters.visible = toggled
	if _margin_container:
		_margin_container.rect_size.y = 0.0


func _on_move_up_pressed() -> void:
	emit_signal("move_up")


func _on_move_down_pressed() -> void:
	emit_signal("move_down")


func _on_remove_pressed() -> void:
	emit_signal("remove_modifier")


func _on_child_resized() -> void:
	if _margin_container:
		rect_min_size.y = _margin_container.rect_size.y


func _on_parameter_value_changed(value, previous, name, ui) -> void:
	if _scatter.undo_redo:
		_scatter.undo_redo.create_action("Changed Value " + name.capitalize())
		_scatter.undo_redo.add_undo_method(self, "_restore_value", name, previous, ui)
		_scatter.undo_redo.add_do_method(self, "_restore_value", name, value, ui)
		_scatter.undo_redo.commit_action()

	_modifier.set(name, value)
	emit_signal("value_changed")


func _on_enable_toggled(pressed: bool):
	_modifier.enabled = pressed
	emit_signal("value_changed")


func _on_warning_changed() -> void:
	var warning = _modifier.get_warning()
	_warning.visible = (warning != "")
	_warning_popup.dialog_text = warning


func _on_warning_icon_pressed() -> void:
	_warning_popup.popup_centered()


func _on_mouse_entered():
	_edit_buttons.visible = true


func _on_mouse_exited():
	_edit_buttons.visible = false
