extends RefCounted

# Utility class that mimics the Input class behavior
#
# This only useful when using actions from the Input class isn't possible,
# like in _unhandled_input or forward_3d_gui_input for example, where you don't
# have a native way to detect if a key was just pressed or released.
#
# How to use:
# Call the feed() method first with the latest event you received, then call
# either of the is_key_* function
#
# If you don't call feed() on the same frame before calling any of these two,
# the behavior is undefined.


var _actions := {}


func feed(event: InputEvent) -> void:
	var key
	if event is InputEventMouseButton:
		key = event.button_index
	elif event is InputEventKey:
		key = event.keycode
	else:
		_cleanup_states()
		return

	if not key in _actions:
		_actions[key] = {
			pressed = event.pressed,
			just_released = not event.pressed,
			just_pressed = event.pressed,
		}
		return

	var pressed = _actions[key].pressed

	if pressed and not event.pressed:
		_actions[key].just_released = true
		_actions[key].just_pressed = false

	if not pressed and event.pressed:
		_actions[key].just_pressed = true
		_actions[key].just_released = false

	if pressed and event.pressed:
		_actions[key].just_pressed = false
		_actions[key].just_released = false

	_actions[key].pressed = event.pressed


func _cleanup_states() -> void:
	for key in _actions:
		_actions[key].just_released = false
		_actions[key].just_pressed = false


func is_key_just_pressed(key) -> bool:
	if key in _actions:
		return _actions[key].just_pressed

	return false


func is_key_just_released(key) -> bool:
	if key in _actions:
		return _actions[key].just_released

	return false
