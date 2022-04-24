@tool
extends TextureRect


func _gui_input(event):
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		owner.dragged.emit(event)
		return

	if event is InputEventMouseButton and not event.is_pressed():
		owner.dragged.emit(null)
