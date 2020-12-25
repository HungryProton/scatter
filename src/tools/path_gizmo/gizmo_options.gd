tool
extends HBoxContainer


signal option_changed


onready var colliders: Button = $Colliders
onready var plane: Button = $Plane

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


func _get_nodes() -> void:
	if not colliders:
		colliders = get_node("Colliders")
	
	if not plane:
		plane = get_node("Plane")


func _on_button_toggled(val: bool) -> void:
	emit_signal("option_changed")
	plane.disabled = snap_to_colliders()
