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

class_name GM_ItemArea

## -- 
## Exported variables
## --
export(int) var proportion : int = 100 setget _set_proportion
export(String, FILE) var item_path : String setget _set_path

## --
## Internal variables
## --

## --
## Public methods
## --

func get_class():
	return "GM_ItemArea"

## --
## Internal methods
## --

func _set_proportion(val):
	proportion = val
	#get_parent().update()

func _set_path(val):
	item_path = val
	#get_parent().update()
