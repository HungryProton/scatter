@tool
extends Button


@export var default_icon: Texture
@export var pressed_icon: Texture


func _ready() -> void:
	toggled.connect(_on_toggled)
	_on_toggled(button_pressed)


func _on_toggled(pressed: bool) -> void:
	if pressed:
		icon = pressed_icon
	else:
		icon = default_icon
