tool
extends Button


export var collapsed_icon: Texture
export var expanded_icon: Texture


func _on_ready() -> void:
	_on_toggled(pressed)


func _on_toggled(pressed: bool) -> void:
	if pressed:
		icon = expanded_icon
	else:
		icon = collapsed_icon
