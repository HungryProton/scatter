tool
extends Spatial


export(int) var proportion : int = 100 setget _set_proportion
export(String, FILE) var item_path : String setget _set_path
export(float) var scale_modifier : float = 1.0 setget _set_scale_modifier
export(bool) var ignore_initial_position : bool = false setget _set_position_flag
export(bool) var ignore_initial_rotation : bool = false setget _set_rotation_flag
export(bool) var ignore_initial_scale : bool = false setget _set_scale_flag

var initial_position
var initial_rotation
var initial_scale

var _parent


func _ready():
	_parent = get_parent()


func _get_configuration_warning() -> String:
	if item_path.empty():
		return "The 'Item Path' variable must points to a valid scene containing the mesh you want to scatter"
	return ""


func update():
	_parent = get_parent()
	if _parent:
		_parent.update()


func _set_proportion(val):
	proportion = val
	update()


func _set_path(val):
	item_path = val

	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)
	
	if not val:
		return

	var instance = load(val).instance()
	initial_position = instance.translation
	initial_rotation = instance.rotation
	initial_scale = instance.scale
	instance.queue_free()
	update()


func _set_scale_modifier(val):
	scale_modifier = val
	update()


func _set_position_flag(val):
	ignore_initial_position = val
	update()


func _set_rotation_flag(val):
	ignore_initial_rotation = val
	update()


func _set_scale_flag(val):
	ignore_initial_scale = val
	update()
