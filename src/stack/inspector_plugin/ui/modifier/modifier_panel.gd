@tool
extends Control


signal dragged
signal removed
signal value_changed


var _scatter
var _modifier

@onready var _parameters: Control = $MarginContainer/VBoxContainer/Parameters
@onready var _name: Label = $MarginContainer/VBoxContainer/HBoxContainer/ModifierName
@onready var _enabled: Button = $MarginContainer/VBoxContainer/HBoxContainer/Buttons/Enabled
@onready var _remove: Button = $MarginContainer/VBoxContainer/HBoxContainer/Buttons/Remove
@onready var _warning: Button = $MarginContainer/VBoxContainer/HBoxContainer/Buttons/Warning
@onready var _warning_dialog: AcceptDialog = $WarningDialog


func _ready() -> void:
	_name.text = name
	_remove.pressed.connect(_on_remove_pressed)


func set_root(val) -> void:
	_scatter = val


func create_ui_for(modifier) -> void:
	_modifier = modifier
	_modifier.warning_changed.connect(_on_warning_changed)
	_on_warning_changed()

	_name.text = modifier.display_name
	_enabled.button_pressed = modifier.enabled

	for property in modifier.get_property_list():
		if property.usage != PROPERTY_USAGE_DEFAULT + PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue

		if property.name == "enabled":
			continue

		var parameter_ui
		match property.type:
			TYPE_BOOL:
				parameter_ui = preload("./components/parameter_bool.tscn").instantiate()
			TYPE_FLOAT:
				parameter_ui = preload("./components/parameter_scalar.tscn").instantiate()
			TYPE_INT:
				parameter_ui = preload("./components/parameter_scalar.tscn").instantiate()
				parameter_ui.mark_as_int(true)
			TYPE_STRING:
				if property.hint_string == "Node":
					parameter_ui = preload("./components/parameter_node_selector.tscn").instantiate()
					parameter_ui.set_root(_scatter)
				elif property.hint_string == "File" or property.hint_string == "Texture":
					parameter_ui = preload("./components/parameter_file.tscn").instantiate()
				elif property.hint_string == "Curve":
					parameter_ui = preload("./components/parameter_curve.tscn").instantiate()
				elif property.hint_string == "bitmask":
					parameter_ui = preload("./components/parameter_bitmask.tscn").instantiate()
				else:
					parameter_ui = preload("./components/parameter_string.tscn").instantiate()
			TYPE_VECTOR3:
				parameter_ui = preload("./components/parameter_vector3.tscn").instantiate()
			TYPE_VECTOR2:
				parameter_ui = preload("./components/parameter_vector2.tscn").instantiate()

		if parameter_ui:
			_parameters.add_child(parameter_ui)
			parameter_ui.set_parameter_name(property.name.capitalize())
			parameter_ui.set_value(modifier.get(property.name))
			parameter_ui.set_hint_string(property.hint_string)
			parameter_ui.value_changed.connect(_on_parameter_value_changed.bind(property.name, parameter_ui))


func _restore_value(name, val, ui) -> void:
	_modifier.set(name, val)
	ui.set_value(val)
	value_changed.emit()


func _on_expand_toggled(toggled: bool) -> void:
	_parameters.visible = toggled


func _on_remove_pressed() -> void:
	removed.emit()


func _on_parameter_value_changed(value, previous, name, ui) -> void:
	if _scatter.undo_redo:
		_scatter.undo_redo.create_action("Changed Value " + name.capitalize())
		_scatter.undo_redo.add_undo_method(self, "_restore_value", name, previous, ui)
		_scatter.undo_redo.add_do_method(self, "_restore_value", name, value, ui)
		_scatter.undo_redo.commit_action()

	_modifier.set(name, value)
	value_changed.emit()


func _on_enable_toggled(pressed: bool):
	_modifier.enabled = pressed
	value_changed.emit()


func _on_removed_pressed() -> void:
	removed.emit()


func _on_warning_changed() -> void:
	var warning = _modifier.get_warning()
	_warning.visible = (warning != "")
	_warning_dialog.dialog_text = warning


func _on_warning_icon_pressed() -> void:
	_warning_dialog.popup_centered()
