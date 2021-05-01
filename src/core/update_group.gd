tool
extends Spatial


var Scatter = preload("namespace.gd").new()

var _is_updating := false


func _ready() -> void:
	set_notify_transform(true)


func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			update()


func update() -> void:
	if _is_updating:
		return

	_is_updating = true
	_update_children_recursive(self)
	_notify_parent()
	_is_updating = false


func _update_children_recursive(node: Node) -> void:
	if node is Scatter.Scatter:
		node.update()

	for child in node.get_children():
		_update_children_recursive(child)


func _notify_parent() -> void:
	var parent = get_parent()
	if not parent:
		return

	if parent is Scatter.Scatter or parent is Scatter.UpdateGroup:
		parent.update()
