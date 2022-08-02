@tool
extends "base_shape.gd"


@export var width := 0.0:
	set(val):
		width = val
		emit_changed()

@export var curve: Curve3D


func get_copy():
	var copy = get_script().new()
	copy.width = width
	curve = curve.duplicate()
	return copy


func copy_from(source) -> void:
	width = source.width
	if source.curve:
		curve = source.curve.duplicate() # TODO, update signals


func create_point(position: Vector3) -> void:
	if not curve:
		curve = Curve3D.new()

	curve.add_point(position)


func remove_point(index):
	if index > curve.get_point_count() - 1:
		return
	curve.remove_point(index)


func get_closest_to(position):
	if curve.get_point_count() == 0:
		return -1

	var closest = -1
	var dist_squared = -1

	for i in curve.get_point_count():
		var point_pos: Vector3 = curve.get_point_position(i)
		var point_dist: float = point_pos.distance_squared_to(position)

		if (closest == -1) or (dist_squared > point_dist):
			closest = i
			dist_squared = point_dist

	var threshold = 16 # Ignore if the closest point is farther than this
	if dist_squared >= threshold:
		return -1

	return closest
