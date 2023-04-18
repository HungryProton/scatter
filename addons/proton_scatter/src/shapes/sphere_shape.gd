@tool
class_name ProtonScatterSphereShape
extends ProtonScatterBaseShape


@export var radius := 1.0:
	set(val):
		radius = val
		_radius_squared = val * val
		emit_changed()

var _radius_squared := 0.0


func get_copy():
	var copy = ProtonScatterSphereShape.new()
	copy.radius = radius
	return copy


func is_point_inside(point: Vector3, global_transform: Transform3D) -> bool:
	var shape_center = global_transform * Vector3.ZERO
	return shape_center.distance_squared_to(point) < _radius_squared


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
		c *= radius
		res.push_back(gt * c)

	return res



# Returns the circle matching the intersection between the transform's XZ plane
# and the sphere. Returns an empty array if there's no intersection
func get_closed_edges(scatter_gt: Transform3D, shape_gt: Transform3D) -> Array[PackedVector2Array]:
	var edge := PackedVector2Array()

	var a = scatter_gt.basis.x
	var b = scatter_gt.basis.z
	var c = a + b
	var o = scatter_gt.origin
	var plane = Plane(a + o, b + o, c + o)

	var sphere_center := shape_gt.origin
	var dist2plane = plane.distance_to(sphere_center)
	var radius_at_ground_level := sqrt(pow(radius, 2) - pow(dist2plane, 2))

	# No intersection with plane
	if radius_at_ground_level <= 0 or radius_at_ground_level > radius:
		return []

	var sphere_center_local = scatter_gt.affine_inverse() * sphere_center

	var origin := Vector2(sphere_center_local.x, sphere_center_local.z)
	var steps: int = max(16, radius_at_ground_level * 12.0)
	var angle: float = TAU / steps

	for i in steps + 1:
		var theta = angle * i
		var point := origin + Vector2(cos(theta), sin(theta)) * radius_at_ground_level
		edge.push_back(point)

	return [edge]
