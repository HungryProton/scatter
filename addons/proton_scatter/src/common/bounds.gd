@tool
extends Resource

# Used by the Domain class
# TODO: This could be replaced by a built-in AABB

var size: Vector3
var center: Vector3
var min: Vector3
var max: Vector3

var _points := 0


func clear() -> void:
	size = Vector3.ZERO
	center = Vector3.ZERO
	min = Vector3.ZERO
	max = Vector3.ZERO
	_points = 0


func feed(point: Vector3) -> void:
	if _points == 0:
		min = point
		max = point

	min = _minv(min, point)
	max = _maxv(max, point)
	_points += 1


# Call this after you've called feed() with all the points in your data set
func compute_bounds() -> void:
	if min == null or max == null:
		return

	size = max - min
	center = min + (size / 2.0)


# Returns a vector with the smallest values in each of the 2 input vectors
func _minv(v1: Vector3, v2: Vector3) -> Vector3:
	return Vector3(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z, v2.z))


# Returns a vector with the highest values in each of the 2 input vectors
func _maxv(v1: Vector3, v2: Vector3) -> Vector3:
	return Vector3(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z, v2.z))

