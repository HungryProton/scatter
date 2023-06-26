@tool
class_name ProtonScatterBaseShape
extends Resource


func is_point_inside_global(_point_global: Vector3, _global_transform: Transform3D) -> bool:
	return false


func is_point_inside_local(_point_local: Vector3) -> bool:
	return false


# Returns an array of Vector3. This should contain enough points to compute
# a bounding box for the given shape.
func get_corners_global(_shape_global_transform: Transform3D) -> Array[Vector3]:
	return []


# Returns the closed contour of the shape (closed, inner and outer if
# applicable) as a 2D polygon, in local space relative to the scatter node.
func get_closed_edges(_shape_t: Transform3D) -> Array[PackedVector2Array]:
	return []


# Returns the open edges (in the case of a regular path, not closed)
# in local space relative to the scatter node.
func get_open_edges(_shape_t: Transform3D) -> Array[Curve3D]:
	return []


# Returns a copy of this shape.
# TODO: check later when Godot4 enters beta if we can get rid of this and use
# the built-in duplicate() method properly.
func get_copy() -> Resource:
	return null
