tool
extends Node

# --
# GM Item Area
# --
# This node must be a child of a GM_FillArea node.
# Gives information about the scene we want to duplicate and spread accross
# the given area.
# Multiple ItemArea nodes can be attached to the same FillArea, just like
# multiple CollisionShape can be attached to a CollisionObject. 
# --
# 
# --

class_name ScatterItem

## -- 
## Exported variables
## --
export(int) var proportion : int = 100 setget _set_proportion
export(String, FILE) var item_path : String setget _set_path
export(float) var scale_modifier : float = 1.0 setget _set_scale_modifier

## --
## Internal variables
## --

var _parent

## --
## Public methods
## --

func get_class():
	return "ScatterItem"

## --
## Internal methods
## --

func _ready():
	_parent = get_parent()

func _set_proportion(val):
	proportion = val
	if _parent:
		_parent.update()

func _set_path(val):
	item_path = val
	if _parent:
		_parent.update()

func _set_scale_modifier(val):
	scale_modifier = val
	if _parent:
		_parent.update()
