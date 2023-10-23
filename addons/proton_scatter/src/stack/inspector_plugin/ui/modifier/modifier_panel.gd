@tool
extends Control


signal value_changed
signal removed
signal documentation_requested
signal duplication_requested


const ParameterBool := preload("./components/parameter_bool.tscn")
const ParameterScalar := preload("./components/parameter_scalar.tscn")
const ParameterNodeSelector = preload("./components/parameter_node_selector.tscn")
const ParameterFile = preload("./components/parameter_file.tscn")
const ParameterCurve = preload("./components/parameter_curve.tscn")
const ParameterBitmask = preload("./components/parameter_bitmask.tscn")
const ParameterString = preload("./components/parameter_string.tscn")
const ParameterVector3 = preload("./components/parameter_vector3.tscn")
const ParameterVector2 = preload("./components/parameter_vector2.tscn")
const PARAMETER_IGNORE_LIST := [
	"enabled",
	"override_global_seed",
	"custom_seed",
	"restrict_height",
	"reference_frame",
	]

var _scatter
var _modifier

@onready var _parameters: Control = $%ParametersRoot
@onready var _name: Label = $%ModifierName
@onready var _expand: Button = $%Expand
@onready var _enabled: Button = $%Enabled
@onready var _remove: Button = $%Remove
@onready var _warning: Button = $%Warning
@onready var _warning_dialog: AcceptDialog = $WarningDialog
@onready var _drag_control: Control = $%DragControl
@onready var _override_ui = $%OverrideGlobalSeed
@onready var _custom_seed_ui = $%CustomSeed
@onready var _restrict_height_ui = $%RestrictHeight
@onready var _transform_space_ui = $%TransformSpace


func _ready() -> void:
	_name.text = name
	_enabled.toggled.connect(_on_enable_toggled)
	_remove.pressed.connect(_on_remove_pressed)
	_warning.pressed.connect(_on_warning_icon_pressed)
	_expand.toggled.connect(_on_expand_toggled)
	$%MenuButton.get_popup().id_pressed.connect(_on_menu_item_pressed)


func _get_drag_data(at_position: Vector2):
	var drag_control_position = _drag_control.global_position - global_position
	var drag_rect := Rect2(drag_control_position, _drag_control.size)
	if drag_rect.has_point(at_position):
		return self

	return null


func set_root(val) -> void:
	_scatter = val


# Loops through all exposed parameters and create an UI component for each of
# them. For special properties (listed in PARAMATER_IGNORE_LIST), a special
# UI is created.
func create_ui_for(modifier) -> void:
	_modifier = modifier
	_modifier.warning_changed.connect(_on_warning_changed)
	_on_warning_changed()

	_name.text = modifier.display_name
	_enabled.button_pressed = modifier.enabled

	# Enable or disable irrelevant controls for this modifier
	_override_ui.enable(modifier.can_override_seed)
	_restrict_height_ui.enable(modifier.can_restrict_height)
	_transform_space_ui.mark_as_enum(true)
	_transform_space_ui.toggle_option_item(0, modifier.global_reference_frame_available)
	_transform_space_ui.toggle_option_item(1, modifier.local_reference_frame_available)
	_transform_space_ui.toggle_option_item(2, modifier.individual_instances_reference_frame_available)
	if not modifier.global_reference_frame_available and \
		not modifier.local_reference_frame_available and \
		not modifier.individual_instances_reference_frame_available:
			_transform_space_ui.visible = false

	# Setup header connections
	_override_ui.value_changed.connect(_on_parameter_value_changed.bind("override_global_seed", _override_ui))
	_custom_seed_ui.value_changed.connect(_on_parameter_value_changed.bind("custom_seed", _custom_seed_ui))
	_restrict_height_ui.value_changed.connect(_on_parameter_value_changed.bind("restrict_height", _restrict_height_ui))
	_transform_space_ui.value_changed.connect(_on_parameter_value_changed.bind("reference_frame", _transform_space_ui))

	# Restore header values
	_override_ui.set_value(modifier.override_global_seed)
	_custom_seed_ui.set_value(modifier.custom_seed)
	_restrict_height_ui.set_value(modifier.restrict_height)
	_transform_space_ui.set_value(modifier.reference_frame)

	# Loop over the other properties and create a ui component for each of them
	for property in modifier.get_property_list():
		if property.usage != PROPERTY_USAGE_DEFAULT + PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue

		if property.name in PARAMETER_IGNORE_LIST:
			continue

		var parameter_ui
		match property.type:
			TYPE_BOOL:
				parameter_ui = ParameterBool.instantiate()
			TYPE_FLOAT:
				parameter_ui = ParameterScalar.instantiate()
			TYPE_INT:
				if property.hint == PROPERTY_HINT_LAYERS_3D_PHYSICS:
					parameter_ui = ParameterBitmask.instantiate()
				else:
					parameter_ui = ParameterScalar.instantiate()
					parameter_ui.mark_as_int(true)
			TYPE_STRING:
				if property.hint_string == "File" or property.hint_string == "Texture":
					parameter_ui = ParameterFile.instantiate()
				else:
					parameter_ui = ParameterString.instantiate()
			TYPE_VECTOR3:
				parameter_ui = ParameterVector3.instantiate()
			TYPE_VECTOR2:
				parameter_ui = ParameterVector2.instantiate()
			TYPE_NODE_PATH:
				parameter_ui = ParameterNodeSelector.instantiate()
				parameter_ui.set_root(_scatter)
			TYPE_OBJECT:
				if property.class_name == &"Curve":
					parameter_ui = ParameterCurve.instantiate()

		if parameter_ui:
			_parameters.add_child(parameter_ui)
			parameter_ui.set_parameter_name(property.name.capitalize())
			parameter_ui.set_value(modifier.get(property.name))
			parameter_ui.set_hint_string(property.hint_string)
			parameter_ui.value_changed.connect(_on_parameter_value_changed.bind(property.name, parameter_ui))

	_expand.button_pressed = _modifier.expanded


func _restore_value(name, val, ui) -> void:
	_modifier.set(name, val)
	ui.set_value(val)
	value_changed.emit()


func _on_expand_toggled(toggled: bool) -> void:
	$%ParametersContainer.visible = toggled
	_modifier.expanded = toggled


func _on_remove_pressed() -> void:
	removed.emit()


func _on_parameter_value_changed(value, previous, parameter_name, ui) -> void:
	if _scatter.undo_redo:
		_scatter.undo_redo.create_action("Change value " + parameter_name.capitalize())
		_scatter.undo_redo.add_undo_method(self, "_restore_value", parameter_name, previous, ui)
		_scatter.undo_redo.add_do_method(self, "_restore_value", parameter_name, value, ui)
		_scatter.undo_redo.commit_action()
	else:
		_modifier.set(parameter_name, value)
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


func _on_menu_item_pressed(id) -> void:
	match id:
		0:
			documentation_requested.emit()
		2:
			duplication_requested.emit()
		3:
			_on_remove_pressed()
		_:
			pass
