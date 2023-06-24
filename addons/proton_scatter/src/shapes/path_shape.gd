@tool
class_name ProtonScatterPathShape
extends ProtonScatterBaseShape


const Bounds := preload("../common/bounds.gd")


@export var closed := true:
	set(val):
		closed = val
		emit_changed()

@export var thickness := 0.0:
	set(val):
		thickness = max(0, val) # Width cannot be negative
		_half_thickness_squared = pow(thickness * 0.5, 2)
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
var _half_thickness_squared: float
var _bounds: Bounds


func is_point_inside(point: Vector3, global_transform: Transform3D) -> bool:
	if not _polygon:
		_update_polygon_from_curve()

	if not _polygon:
		return false

	point = global_transform.affine_inverse() * point

	if thickness > 0:
		var closest_point_on_curve: Vector3 = curve.get_closest_point(point)
		var dist2 = closest_point_on_curve.distance_squared_to(point)
		if dist2 < _half_thickness_squared:
			return true

	if closed:
		return _polygon.is_point_inside(Vector2(point.x, point.z))

	return false


func get_corners_global(gt: Transform3D) -> Array:
	var res := []

	if not curve:
		return res

	var half_thickness = thickness * 0.5
	var corners = [
		Vector3(-1, -1, -1),
		Vector3(1, -1, -1),
		Vector3(1, -1, 1),
		Vector3(-1, -1, 1),
		Vector3(-1, 1, -1),
		Vector3(1, 1, -1),
		Vector3(1, 1, 1),
		Vector3(-1, 1, 1),
	]

	var points = curve.tessellate(3, 10)
	for p in points:
		res.push_back(gt * p)

		if thickness > 0:
			for offset in corners:
				res.push_back(gt * (p + offset * half_thickness))

	return res


func get_bounds() -> Bounds:
	if not _bounds:
		_update_polygon_from_curve()
	return _bounds


func get_copy():
	var copy = get_script().new()

	copy.thickness = thickness
	copy.closed = closed
	if curve:
		copy.curve = curve.duplicate()

	return copy


func copy_from(source) -> void:
	thickness = source.thickness
	if source.curve:
		curve = source.curve.duplicate() # TODO, update signals


# TODO: create points in the middle of the path
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


func get_closed_edges(shape_t: Transform3D) -> Array[PackedVector2Array]:
	if not closed and thickness <= 0:
		return []

	if not curve:
		return []

	var edges: Array[PackedVector2Array] = []
	var polyline := PackedVector2Array()
	var shape_t_inverse := shape_t.affine_inverse()
	var points := curve.tessellate(5, 5) # TODO: find optimal values

	for p in points:
		p *= shape_t_inverse # Apply the shape node transform
		polyline.push_back(Vector2(p.x, p.z))

	if closed:
		# Ensure the polygon is closed
		var first_point: Vector3 = points[0]
		var last_point: Vector3 = points[-1]

		if first_point != last_point:
			first_point *= shape_t_inverse
			polyline.push_back(Vector2(first_point.x, first_point.z))

	# Prevents the polyline to be considered as a hole later.
	if Geometry2D.is_polygon_clockwise(polyline):
		polyline.reverse()

	# Expand the polyline to get the outer edge of the path.
	if thickness > 0:
		# WORKAROUND. We cant specify the round end caps resolution, but it's tied to the polyline
		# size. So we scale everything up before calling offset_polyline(), then scale the result
		# down so we get rounder caps.
		var scale = 5.0 * thickness
		var delta = (thickness / 2.0) * scale

		var t2 = Transform2D().scaled(Vector2.ONE * scale)
		var result := Geometry2D.offset_polyline(polyline * t2, delta, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)

		t2 = Transform2D().scaled(Vector2.ONE * (1.0 / scale))
		for polygon in result:
			edges.push_back(polygon * t2)

	if closed and thickness == 0.0:
		edges.push_back(polyline)

	return edges


func get_open_edges(shape_t: Transform3D) -> Array[Curve3D]:
	if not curve or closed or thickness > 0:
		return []

	var res := Curve3D.new()
	var shape_t_inverse := shape_t.affine_inverse()

	for i in curve.get_point_count():
		var pos = curve.get_point_position(i)
		var pos_t = pos * shape_t_inverse
		var p_in = (curve.get_point_in(i) + pos) * shape_t_inverse - pos_t
		var p_out = (curve.get_point_out(i) + pos) * shape_t_inverse - pos_t
		res.add_point(pos_t, p_in, p_out)

	return [res]


func _update_polygon_from_curve() -> void:
	var connections = PackedInt32Array()
	var polygon_points = PackedVector2Array()

	if not _bounds:
		_bounds = Bounds.new()

	_bounds.clear()
	_polygon = PolygonPathFinder.new()

	if not curve:
		curve = Curve3D.new()

	if curve.get_point_count() == 0:
		return

	var baked_points = curve.tessellate(4, 6)
	var steps := baked_points.size()

	for i in baked_points.size():
		var point = baked_points[i]
		var projected_point = Vector2(point.x, point.z)
		_bounds.feed(point)

		polygon_points.push_back(projected_point)
		connections.append(i)
		if i == steps - 1:
			connections.append(0)
		else:
			connections.append(i + 1)

	_bounds.compute_bounds()
	_polygon.setup(polygon_points, connections)


func _on_curve_changed() -> void:
	_update_polygon_from_curve()
	emit_changed()
