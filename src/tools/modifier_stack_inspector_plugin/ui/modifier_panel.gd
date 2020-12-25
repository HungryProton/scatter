tool
extends Control


signal move_up
signal move_down
signal remove_modifier
signal value_changed


var _modifier

onready var _parameters: Control = $MarginContainer/VBoxContainer/Parameters
onready var _name: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label
onready var _margin_container: MarginContainer = $MarginContainer


func _ready() -> void:
	_margin_container.connect("resized", self, "_on_child_resized")


func create_ui_for(modifier) -> void:
	_modifier = modifier
	_name.text = modifier.display_name
	
	for property in modifier.get_property_list():
		if property.usage != PROPERTY_USAGE_DEFAULT + PROPERTY_USAGE_SCRIPT_VARIABLE:
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
				parameter_ui = preload("./components/parameter_string.tscn").instance()
			TYPE_VECTOR3:
				parameter_ui = preload("./components/parameter_vector3.tscn").instance()
			
		if parameter_ui:
			_parameters.add_child(parameter_ui)
			parameter_ui.set_parameter_name(property.name.capitalize())
			parameter_ui.set_value(modifier.get(property.name))
			parameter_ui.connect("value_changed", self, "_on_parameter_value_changed", [property.name])


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


func _on_parameter_value_changed(value, name) -> void:
	_modifier.set(name, value)
	emit_signal("value_changed")
