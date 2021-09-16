tool
extends Control


signal option_changed
signal color_changed
signal snap_to_colliders_enabled


onready var _colliders: Button = $VBoxContainer/Colliders
onready var _plane: Button = $VBoxContainer/Plane
onready var _options_button: Button = $VBoxContainer/Options
onready var _options: Control = $VBoxContainer/MarginContainer
onready var _grid_density: SpinBox = $VBoxContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GridDensity/SpinBox
onready var _hide_grid: CheckButton = $VBoxContainer/MarginContainer/VBoxContainer/HideGrid
onready var _force_plane_projection: CheckButton = $VBoxContainer/MarginContainer/VBoxContainer/ForceProjection
onready var _path_color: ColorRect = $VBoxContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/PathColor/MarginContainer/Button/ColorRect
onready var _grid_color: ColorRect = $VBoxContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GridColor/MarginContainer/Button/ColorRect
onready var _color_picker: ColorPicker = $Popup/MarginContainer/ColorPicker
onready var _color_popup: Popup = $Popup


var _selected_color


func _ready() -> void:
	if not _load_config_file():
		_save_config_file()


func snap_to_colliders() -> bool:
	return _colliders.pressed


# This option is disabled when snap_to_colliders is enabled
func lock_to_plane() -> bool:
	if snap_to_colliders():
		return false

	return _plane.pressed


func hide_grid() -> bool:
	return _hide_grid.pressed


func force_plane_projection() -> bool:
	return _force_plane_projection.pressed


func get_path_color() -> Color:
	return _path_color.color


func get_grid_color() -> Color:
	return _grid_color.color


func get_grid_density() -> float:
	return _grid_density.value


# Auto hide the extra options
func _set(property, value):
	if property == "visible":
		_options_button.pressed = false
		_on_option_button_toggled(false)
	return false


func _show_color_picker() -> void:
	var origin := get_global_transform().origin
	origin.x += rect_size.x + 12
	_color_popup.popup(Rect2(origin, Vector2.ONE))


func _load_config_file() -> bool:
	var config := ConfigFile.new()
	var err = config.load("user://scatter_config.cfg")

	if err != OK:
		return false

	_path_color.color = config.get_value("colors", "path", Color("ff2f2f"))
	_grid_color.color = config.get_value("colors", "grid", Color("c8ffbe11"))

	_colliders.pressed = config.get_value("general", "snap_to_colliders", false)
	_plane.pressed = config.get_value("general", "lock_to_plane", true)
	_hide_grid.pressed = config.get_value("general", "always_hide_grid", false)
	_grid_density.value = config.get_value("general", "grid_density", 7)
	_force_plane_projection.pressed = config.get_value("general", "force_plane_projection", false)

	return true


func _save_config_file() -> void:
	var config := ConfigFile.new()

	config.set_value("colors", "path", _path_color.color)
	config.set_value("colors", "grid", _grid_color.color)
	config.set_value("general", "snap_to_colliders", _colliders.pressed)
	config.set_value("general", "lock_to_plane", _plane.pressed)
	config.set_value("general", "always_hide_grid", _hide_grid.pressed)
	config.set_value("general", "grid_density", _grid_density.value)
	config.set_value("general", "force_plane_projection", _force_plane_projection.pressed)

	config.save("user://scatter_config.cfg")


func _on_button_toggled(val: bool) -> void:
	emit_signal("option_changed")
	_save_config_file()


func _on_snap_button_toggled(val: bool) -> void:
	_plane.disabled = snap_to_colliders()
	if val:
		emit_signal("snap_to_colliders_enabled")


func _on_option_button_toggled(pressed: bool) -> void:
	_options.visible = pressed
	if pressed:
		_options_button.text = "Hide extra options"
	else:
		_options_button.text = "Show extra options"


func _on_path_color_select():
	_selected_color = _path_color
	_color_picker.color = _path_color.color
	_show_color_picker()


func _on_grid_color_select():
	_selected_color = _grid_color
	_color_picker.color = _grid_color.color
	_show_color_picker()


func _on_color_changed(color):
	_selected_color.color = color
	emit_signal("color_changed")
	_save_config_file()
