@tool
class_name ProtonScatterBoxShape
extends ProtonScatterBaseShape


@export var size := Vector3.ONE:
	set(val):
		size = val
		_half_size = size * 0.5
		emit_changed()

var _half_size := Vector3.ONE


func get_copy():
	var copy = get_script().new()
	copy.size = size
	return copy


func is_point_inside(point: Vector3, global_transform: Transform3D) -> bool:
	var position = global_transform * -_half_size
	var local_point = global_transform.affine_inverse() * point
	return AABB(-_half_size, size).has_point(local_point)


func get_corners_global(gt: Transform3D) -> Array:
	var res := []
	var corners := [
		Vector3(-1, -1, -1),
		Vector3(-1, -1, 1),
		Vector3(1, -1, 1),
		Vector3(1, -1, -1),
		Vector3(-1, 1, -1),
		Vector3(-1, 1, 1),
		Vector3(1, 1, 1),
		Vector3(1, 1, -1),
	]

	for c in corners:
		c *= size * 0.5
		res.push_back(gt * c)

	return res


# Intersection between and box and a plane results in a polygon between 3 and 6
# vertices.
# Compute the intersection of each of the 12 edges to the plane, then recompute
# the polygon from the positions found.
func get_closed_edges(scatter_gt: Transform3D, shape_gt: Transform3D) -> Array[PackedVector2Array]:
	var polygon := PackedVector2Array()

	var a = scatter_gt.basis.x
	var b = scatter_gt.basis.z
	var c = a + b
	var o = scatter_gt.origin
	var plane = Plane(a + o, b + o, c + o)

	var box_edges := [
		# Bottom square
		[Vector3(-1, -1, -1), Vector3(-1, -1, 1)],
		[Vector3(-1, -1, 1), Vector3(1, -1, 1)],
		[Vector3(1, -1, 1), Vector3(1, -1, -1)],
		[Vector3(1, -1, -1), Vector3(-1, -1, -1)],

		# Top square
		[Vector3(-1, 1, -1), Vector3(-1, 1, 1)],
		[Vector3(-1, 1, 1), Vector3(1, 1, 1)],
		[Vector3(1, 1, 1), Vector3(1, 1, -1)],
		[Vector3(1, 1, -1), Vector3(-1, 1, -1)],

		# Vertical lines
		[Vector3(-1, -1, -1), Vector3(-1, 1, -1)],
		[Vector3(-1, -1, 1), Vector3(-1, 1, 1)],
		[Vector3(1, -1, 1), Vector3(1, 1, 1)],
		[Vector3(1, -1, -1), Vector3(1, 1, -1)],
	]

	var intersection_points := PackedVector3Array()
	var point
	var gt_inverse := scatter_gt.affine_inverse()
	var shape_gt_inverse := shape_gt.affine_inverse()

	for edge in box_edges:
		var p1 = (edge[0] * _half_size) * shape_gt_inverse
		var p2 = (edge[1] * _half_size) * shape_gt_inverse
		point = plane.intersects_segment(p1, p2)
		if point:
			intersection_points.push_back(gt_inverse * point)

	if intersection_points.size() < 3:
		return []

	var points_unordered := PackedVector2Array()
	for p in intersection_points:
		points_unordered.push_back(Vector2(p.x, p.z))

	polygon = Geometry2D.convex_hull(points_unordered)

	return [polygon]
