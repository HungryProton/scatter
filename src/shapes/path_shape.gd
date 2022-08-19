@tool
extends "base_shape.gd"


@export var closed := true:
	set(val):
		closed = val
		emit_changed()

@export var width := 0.0:
	set(val):
		width = max(0, val) # Width cannot be negative
		_half_width_squared = pow(width * 0.5, 2)
		emit_changed()

@export var curve: Curve3D:
	set(val):
		# Disconnect previous signal
		if curve and curve.changed.is_connected(_on_curve_changed):
			curve.changed.disconnect(_on_curve_changed)

		curve = val
		curve.changed.connect(_on_curve_changed)
		emit_changed()


var _polygon: PolygonPathFinder
var _half_width_squared: float


func is_point_inside(point: Vector3, global_transform: Transform3D) -> bool:
	if not _polygon:
		_update_polygon_from_curve()

	point = global_transform.affine_inverse() * point

	if width > 0:
		var closest_point_on_curve: Vector3 = curve.get_closest_point(point)
		var dist2 = closest_point_on_curve.distance_squared_to(point)
		if dist2 < _half_width_squared:
			return true

	if closed:
		return _polygon.is_point_inside(Vector2(point.x, point.z))

	return false


func get_corners_global(gt: Transform3D) -> Array:
	var res := []

	var points = curve.tessellate(3, 10)
	for i in points.size() - 1:
		var p1 = points[i]
		var p2 = points[i + 1]
		var n = (p2 - p1).cross(Vector3.UP).normalized()
		var offset = n * width * 0.5

		res.push_back(gt * (p1 + offset))
		res.push_back(gt * (p1 - offset))

	return res


func get_copy():
	var copy = get_script().new()
	copy.width = width
	copy.curve = curve.duplicate()
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


func get_closed_edges(transform: Transform3D) -> Array[PackedVector2Array]:
	if not closed and width <= 0:
		return []

	var polyline := PackedVector2Array()
	var points := curve.tessellate(5, 5) # TODO: find optimal values
	var origin = Vector2(transform.origin.x, transform.origin.z)
	for p in points:
		polyline.push_back(origin + Vector2(p.x, p.z))

	if width > 0:
		var delta = width / 2.0
		return Geometry2D.offset_polyline(polyline, delta, Geometry2D.JOIN_SQUARE, Geometry2D.END_ROUND)
	else:
		return [polyline]


func get_open_edges(transform: Transform3D) -> Array[Curve3D]:
	if closed or width > 0:
		return []

	if curve == null:
		return []

	return [curve.duplicate()]


func _update_polygon_from_curve() -> void:
	var connections = PackedInt32Array()
	var polygon_points = PackedVector2Array()

	if not curve:
		curve = Curve3D.new()
		return

	if curve.get_point_count() == 0:
		return

	if not _polygon:
		_polygon = PolygonPathFinder.new()

	var baked_points = curve.tessellate(4, 6)
	var steps := baked_points.size()

	for i in baked_points.size():
		var point = baked_points[i]
		var projected_point = Vector2(point.x, point.z)

		polygon_points.push_back(projected_point)
		connections.append(i)
		if i == steps - 1:
			connections.append(0)
		else:
			connections.append(i + 1)

	_polygon.setup(polygon_points, connections)


func _on_curve_changed() -> void:
	_update_polygon_from_curve()
	emit_changed()
