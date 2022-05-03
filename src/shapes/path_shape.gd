@tool
extends "base_shape.gd"


@export var width := 0.0:
	set(val):
		width = val
		emit_changed()

var curve: Curve3D
