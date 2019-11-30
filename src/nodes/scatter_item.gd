# --
# ScatterItem
# --
# This node must be a child of either a ScatterDuplicates or a ScatterMultimesh node.
# Gives information about the scene we want to duplicate and spread accross
# the given area.
# Multiple ScatterItems nodes can be attached to the same Scatter*, just like
# multiple CollisionShape can be attached to a CollisionObject.
# --

tool

extends Spatial

class_name ScatterItem

## --
## Exported variables
## --

export(int) var proportion : int = 100 setget _set_proportion
export(String, FILE) var item_path : String setget _set_path
export(float) var scale_modifier : float = 1.0 setget _set_scale_modifier
export(bool) var ignore_initial_position : bool = false setget _set_position_flag
export(bool) var ignore_initial_rotation : bool = false setget _set_rotation_flag
export(bool) var ignore_initial_scale : bool = false setget _set_scale_flag

## --
## Public variables
## --

var initial_position
var initial_rotation
var initial_scale

## --
## Internal variables
## --

var _parent
var _exclusion_areas : Array

## --
## Public methods
## --

func get_class():
	return "ScatterItem"

func get_exclusion_areas():
	var result = _parent.get_exclusion_areas()
	for c in get_children():
		if c.get_class() == "ScatterExclude":
			result.append(c)
	return result

func update():
	_parent = get_parent()
	if _parent:
		_parent.update()

## --
## Internal methods
## --

func _ready():
	_parent = get_parent()

func _set_proportion(val):
	proportion = val
	update()

func _set_path(val):
	item_path = val
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
