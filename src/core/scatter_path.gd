tool
extends Path


signal curve_updated

export var bake_interval := 2.0

var polygon : PolygonPathFinder
var polygon_points : PoolVector2Array
var size : Vector3
var center : Vector3
var closed_curve : bool = false


func _ready():
	self.connect("curve_changed", self, "_on_curve_changed")
	_update_from_curve()


func is_point_inside(point : Vector3):
	if not polygon:
		_update_from_curve()
	return polygon.is_point_inside(_get_projected_coords(point))


func add_point(position):
	if not curve:
		curve = Curve3D.new()
	
	curve.add_point(position)
	var current_index = curve.get_point_count() - 1
	var previous_index = current_index - 1
	if previous_index < 0:
		curve.set_point_in(current_index, Vector3(-1.0, 0.0, 0.0))
		curve.set_point_out(current_index, Vector3(1.0, 0.0, 0.0))
		return
	
	var dir = position - curve.get_point_position(previous_index)
	var dir_out = dir.normalized()
	var dir_in = -dir.normalized()
	
	curve.set_point_in(current_index, dir_in)
	curve.set_point_out(current_index, dir_out)
	
	_update_from_curve()


func remove_point(index):
	if index > curve.get_point_count() - 1:
		return
	curve.remove_point(index)
	_update_from_curve()
 

func set_closed_curve(value):
	closed_curve = value
	if closed_curve:
		# Create a new point, duplicate the first point data
		pass
	_update_from_curve()


func set_point_position(index, pos):
	curve.set_point_position(index, pos)
	_update_from_curve()


func set_point_in(index, pos):
	curve.set_point_in(index, pos)
	_update_from_curve()


func set_point_out(index, pos):
	curve.set_point_out(index, pos)
	_update_from_curve()


func get_closest_to(pos):
	var closest = -1
	var dist_squared = -1
	
	for i in range(0, curve.get_point_count()):
		var point_pos = curve.get_point_position(i)
		var point_dist = point_pos.distance_squared_to(pos)
		
		if (closest == -1) or (dist_squared > point_dist):
			closest = i
			dist_squared = point_dist
	
	var threshold = 16 # Ignore if the closest point is farther than this
	if dist_squared >= threshold:
		return -1
	
	return closest


func remove_closest_to(pos):
	if curve.get_point_count() > 0:
		var closest = get_closest_to(pos)
		remove_point(closest)


func _get_projected_coords(coords : Vector3):
	return Vector2(coords.x, coords.z)


# Travel the whole path to update the polygon and bounds
func _update_from_curve():
	var _min = null
	var _max = null
	var connections = PoolIntArray()
	polygon_points = PoolVector2Array()
	
	if not curve:
		curve = Curve3D.new()
	
	var length = curve.get_baked_length()
	var steps = round(length / bake_interval)
	
	if steps == 0:
		return

	for i in range(steps):
		# Get a point on the curve
		var coords_3d = curve.interpolate_baked((i / (steps - 2)) * length)
		var coords = _get_projected_coords(coords_3d)
		
		# Store polygon data
		polygon_points.append(coords)
		connections.append(i)
		if(i == steps - 1):
			connections.append(0)
		else:
			connections.append(i + 1)
		
		# Check for bounds
		if i == 0:
			_min = coords
			_max = coords
		else:
			if coords.x > _max.x:
				_max.x = coords.x
			if coords.x < _min.x:
				_min.x = coords.x
			if coords.y > _max.y:
				_max.y = coords.y
			if coords.y < _min.y:
				_min.y = coords.y
	
	if not polygon:
		polygon = PolygonPathFinder.new()
	polygon.setup(polygon_points, connections)
	size = Vector3(_max.x - _min.x, 0.0, _max.y - _min.y)
	center = Vector3((_min.x + _max.x) / 2, 0.0, (_min.y + _max.y) / 2)
	
	emit_signal("curve_updated")


func _on_curve_changed() -> void:
	_update_from_curve()
