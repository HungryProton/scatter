@tool
extends "base_shape.gd"


@export var radius := 5.0:
	set(val):
		radius = val
		emit_changed()
