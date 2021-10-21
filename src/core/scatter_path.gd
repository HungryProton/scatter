tool
extends Path


signal curve_updated


export var curve_tolerance_degrees := 5.0 setget _set_curve_tolerance_degrees

var polygon : PolygonPathFinder
var baked_points : PoolVector3Array
var size : Vector3
var center : Vector3
var bounds_max
var bounds_min
var closed_curve : bool = false

var _previous_transform: Transform


func _ready():
	set_notify_transform(true)
	# warning-ignore:return_value_discarded
	connect("curve_changed", self, "_on_curve_changed")
	_update_from_curve()


func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			if _previous_transform != transform:
				_previous_transform = transform
				emit_signal("curve_updated")


func is_point_inside(point : Vector3):
	if not polygon:
		_update_from_curve()

	if not polygon:
		return false

	return polygon.is_point_inside(_get_projected_coords(point))


func distance_from_point(point: Vector3, ignore_height := false) -> float:
	var offset: float = curve.get_closest_offset(point)
	var point_on_curve: Vector3 = curve.interpolate_baked(offset)
	if ignore_height:
		point.y = 0.0
		point_on_curve.y = 0.0

	return point.distance_to(point_on_curve)


func get_pos_and_normal(offset : float) -> Array:
	var pos: Vector3 = curve.interpolate_baked(offset)
	var normal := Vector3.ZERO

	var pos1
	if offset + curve.get_bake_interval() < curve.get_baked_length():
		pos1 = curve.interpolate_baked(offset + curve.get_bake_interval())
		normal = (pos1 - pos)
	else:
		pos1 = curve.interpolate_baked(offset - curve.get_bake_interval())
		normal = (pos - pos1)

	return [pos, normal]


func _get_projected_coords(coords : Vector3):
	return Vector2(coords.x, coords.z)


# Travel the whole path to update the polygon and bounds
func _update_from_curve():
	bounds_max = null
	bounds_min = null
	var connections = PoolIntArray()
	var polygon_points = PoolVector2Array()

	if not curve:
		curve = Curve3D.new()
		return

	if curve.get_point_count() == 0:
		return

	if not polygon:
		polygon = PolygonPathFinder.new()

	baked_points = curve.tessellate(4, curve_tolerance_degrees)

	var steps := baked_points.size()

	for i in baked_points.size():
		var point = baked_points[i]
		var projected_point = _get_projected_coords(point)

		# Store polygon data
		polygon_points.push_back(projected_point)
		connections.append(i)
		if i == steps - 1:
			connections.append(0)
		else:
			connections.append(i + 1)

		# Check for bounds
		if i == 0:
			bounds_min = point
			bounds_max = point
		else:
			if point.x > bounds_max.x:
				bounds_max.x = point.x
			if point.x < bounds_min.x:
				bounds_min.x = point.x
			if point.y > bounds_max.y:
				bounds_max.y = point.y
			if point.y < bounds_min.y:
				bounds_min.y = point.y
			if point.z > bounds_max.z:
				bounds_max.z = point.z
			if point.z < bounds_min.z:
				bounds_min.z = point.z

	polygon.setup(polygon_points, connections)
	size = Vector3(bounds_max.x - bounds_min.x, bounds_max.z - bounds_min.z, bounds_max.z - bounds_min.z)
	center = Vector3((bounds_min.x + bounds_max.x) / 2, (bounds_min.y + bounds_max.y) / 2, (bounds_min.z + bounds_max.z) / 2)

	emit_signal("curve_updated")


func _set_curve_tolerance_degrees(val) -> void:
	curve_tolerance_degrees = val
	_update_from_curve()


func _on_curve_changed() -> void:
	_update_from_curve()
