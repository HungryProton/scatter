@tool
extends Container

# DragContainer
# Custom containner similar to a VBoxContainer, but the user can rearrange the
# children order via drag and drop. This is only used in the inspector plugin
# for the modifier stack and won't work with arbitrary control nodes.


signal child_moved(last_index: int, new_index: int)


@export var separation := 4

var _drag_offset = null
var _dragged_child = null
var _old_index: int
var _new_index: int
var _map := [] # Stores the y top position of each child in the stack


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN or what == NOTIFICATION_RESIZED:
		_update_layout()

		# This check happens way too often but I haven't found a reliable
		# way to detect when new children are added to the container so we enfore
		# signals connections here.
		for c in get_children():
			if not c.dragged.is_connected(_on_child_dragged):
				c.dragged.connect(_on_child_dragged.bind(c))


func _update_layout() -> void:
	_map.clear()
	var offset := Vector2.ZERO

	for c in get_children():
		if c is Control:
			_map.push_back(offset.y)
			var child_min_size = c.get_combined_minimum_size()
			var possible_space = Rect2(offset, Vector2(size.x, child_min_size.y))

			if c != _dragged_child:
				fit_child_in_rect(c, possible_space)

			offset.y += c.size.y + separation

	minimum_size.y = offset.y - separation


func _on_child_dragged(event: InputEventMouseMotion, child: Control) -> void:
	if not event: # Drag stopped
		_drag_offset = null
		_dragged_child = null
		_update_layout()

		# If the child current_index doesn't match the one from before the drag, notify the parent
		if _old_index != _new_index:
			child_moved.emit(_old_index, _new_index)

		return

	if not _dragged_child: # Drag just started
		_dragged_child = child
		_drag_offset = event.position.y
		_old_index = child.get_index()
		_new_index = _old_index

	# Dragged control only follow the y mouse position
	child.position.y = get_local_mouse_position().y - _drag_offset

	# Check if the children order should be changed
	var computed_index = 0
	for pos_y in _map:
		if pos_y > child.position.y - 16:
			break
		computed_index += 1

	if computed_index != child.get_index():
		move_child(child, computed_index)
		_new_index = computed_index
