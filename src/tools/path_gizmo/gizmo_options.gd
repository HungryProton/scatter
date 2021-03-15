tool
extends Control


signal option_changed
signal snap_to_colliders_enabled


onready var colliders: Button = $VBoxContainer/Colliders
onready var plane: Button = $VBoxContainer/Plane
onready var options_button: Button = $VBoxContainer/Options
onready var options: Control = $VBoxContainer/MarginContainer


var path


func snap_to_colliders() -> bool:
	_get_nodes()
	return colliders.pressed


# This option is disabled when snap_to_colliders is enabled
func lock_to_plane() -> bool:
	if snap_to_colliders():
		return false

	_get_nodes()
	return plane.pressed


func _set(property, value):
	if property == "visible":
		options_button.pressed = false
		_on_option_button_toggled(false)
	return false


func _get_nodes() -> void:
	if not colliders:
		colliders = get_node("Colliders")

	if not plane:
		plane = get_node("Plane")


func _on_button_toggled(val: bool) -> void:
	emit_signal("option_changed")
	plane.disabled = snap_to_colliders()


func _on_snap_button_toggled(val: bool) -> void:
	if val:
		emit_signal("snap_to_colliders_enabled")


func _on_option_button_toggled(pressed: bool) -> void:
	options.visible = pressed
	if pressed:
		options_button.text = "Hide extra options"
	else:
		options_button.text = "Show extra options"

