tool
extends Spatial


export(int) var proportion : int = 100 setget _set_proportion
export(String, FILE) var item_path : String setget _set_path
export(float) var scale_modifier : float = 1.0 setget _set_scale_modifier

var _parent


func _ready():
	_parent = get_parent()


func _get_configuration_warning() -> String:
	if item_path.empty():
		return "The 'Item Path' variable must points to a valid scene containing the mesh you want to scatter"
	return ""


func _set(property, value):
	# Hack to detect if the node was just duplicated from the editor
	if property == "transform":
		call_deferred("_delete_multimesh")


func update():
	_parent = get_parent()
	if _parent:
		_parent.update()


func _delete_multimesh() -> void:
	if has_node("MultiMeshInstance"):
		get_node("MultiMeshInstance").queue_free()


func _set_proportion(val):
	proportion = val
	update()


func _set_path(val):
	item_path = val

	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)
	
	if not val:
		return

	update()


func _set_scale_modifier(val):
	scale_modifier = val
	update()
