@tool
extends Container

# DragContainer
# Custom containner similar to a VBoxContainer, but the user can rearrange the
# children order via drag and drop. This is only used in the inspector plugin
# for the modifier stack and won't work with arbitrary control nodes.


@export var separation := 4

var _drag_offset = null
var _dragged_child = null
var _map := [] # Stores the y top position of each child in the stack


func _ready() -> void:
	for c in get_children():
		c.dragged.connect(_on_child_dragged.bind(c))


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN or what == NOTIFICATION_RESIZED:
		_update_layout()


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
		return

	if not _dragged_child: # Drag just started
		_dragged_child = child
		_drag_offset = event.position.y

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
