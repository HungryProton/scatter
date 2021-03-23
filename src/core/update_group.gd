tool
extends Spatial


var Scatter = preload("namespace.gd").new()

var _is_updating := false


func notify_update() -> void:
	if _is_updating:
		return

	_is_updating = true
	_update_children_recursive(self)
	_is_updating = false


func _update_children_recursive(node: Node) -> void:
	if node is Scatter.Scatter:
		node.update()

	for child in node.get_children():
		_update_children_recursive(child)
