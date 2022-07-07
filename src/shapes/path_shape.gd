@tool
extends "base_shape.gd"


@export var width := 0.0:
	set(val):
		width = val
		emit_changed()

@export var curve: Curve3D
