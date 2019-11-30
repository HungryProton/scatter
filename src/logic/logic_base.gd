# --
# ScatterLogic
# --
# Abstract base class to define the logic behind how instances are transformed.
# If the user wants to place instances in a specific way that's not covered
# by the default generic logic, they can create a new custom one that
# inherits this class.
# --

tool

extends ScatterResource

class_name ScatterLogic

## --
## Public variables
## --

# The total amount of instances that will be spawned and placed in the world.
# It's not directly exposed to the end user in case you want to add a special
# logic that changes the amount of instances base on other parameters.
# The Scatter nodes will use this value so remember to update it
var amount : int = 0

# The total amount of scatter items used
var scatter_items_count : int = 0

## --
## Internal variables
## --

var _path : PolygonPath

## --
## Public methods
## --

# The following methods are called in order by the Scatter node

# Init is called once before placing any instances
func init(node : PolygonPath) -> void:
	_path = node

# Since a Scatter node can hold any amount of ScatterItems, this method is called
# once for each ScatterItem. If you need to initialize something on a per item
# basis, this is where it should happen
func scatter_pre_hook(_item : ScatterItem) -> void:
	pass

# The most important function. It will be called for every instances that needs
# to be placed by the Scatter node so idealy it should return a different one
# each time.
func get_next_transform(_item : ScatterItem, _index : int = -1) -> Transform:
	return Transform()

# Called once after every instances for a given item have been placed.
func scatter_post_hook(_item : ScatterItem) -> void:
	pass
