@tool
extends Button


@onready var _popup: PopupPanel = $ModifiersPopup


func _ready() -> void:
	_popup.popup_hide.connect(_on_popup_closed)


func _toggled(button_pressed):
	if button_pressed:
		_popup.position = global_position + Vector2(0.0, size.y)
		_popup.popup()


func _on_popup_closed() -> void:
	button_pressed = false
