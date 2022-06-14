extends Resource


var owner: Node3D # The ScatterShape node it's attached to.


# point must be in global space
func is_point_inside(point: Vector3) -> bool:
	return false


# Returns an array of Vector3. This should contain enough points to compute
# a bounding box for the given shape.
func get_corners() -> Array:
	return []
