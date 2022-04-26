@tool
extends TextureRect


var _is_dragged := false


func _gui_input(event):
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		_is_dragged = true
		owner.dragged.emit(event)
		return

	if event is InputEventMouseButton and not event.is_pressed() and _is_dragged:
		_is_dragged = false
		owner.dragged.emit(null)
