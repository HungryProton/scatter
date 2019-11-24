# --
# BasePositioning
# --
# Base class to define the instances positioning logic.
# If the user wants to place instances in a specific way that's not covered
# by the default generic logic, they can create a new custom one that
# inherits this class.
# --

tool

extends Resource

class_name BasePositioning

## --
## Exported variables
## --

## --
## Public variables
## --

var amount : int = 0
var transforms : Array = []

## --
## Internal variables
## --

var _path : PolygonPath

## --
## Getters and Setters
## --

## --
## Public methods
## --

func init(node : PolygonPath) -> void:
	_path = node

func get_next_transform(_item : ScatterItem, _index : int = -1) -> Transform:
	return Transform()

## --
## Internal methods
## --

## --
## Callbacks
## --
