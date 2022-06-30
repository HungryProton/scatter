@tool
extends "base_shape.gd"


@export var radius := 5.0:
	set(val):
		radius = val
		_radius_squared = val * val
		emit_changed()

var _radius_squared := 0


func get_copy():
	var copy = get_script().new()
	copy.radius = radius
	return copy


func is_point_inside(point: Vector3, global_transform: Transform3D) -> bool:
	var shape_center = global_transform * Vector3.ZERO
	return shape_center.distance_squared_to(point) < _radius_squared


func get_corners_global(gt: Transform3D) -> Array:
	var res := []

	# We're only returning 6 points instead of the 8 corners of the actual
	# bounding box but this is just a sphere so it should be fine.
	var up = Vector3.UP * radius
	var down = Vector3.DOWN * radius
	var left = Vector3.LEFT * radius
	var right = Vector3.RIGHT * radius
	var front = Vector3.FORWARD * radius
	var back = Vector3.BACK * radius

	res.push_back(gt * up)
	res.push_back(gt * down)
	res.push_back(gt * left)
	res.push_back(gt * right)
	res.push_back(gt * front)
	res.push_back(gt * back)

	return res
