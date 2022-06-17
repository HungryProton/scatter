extends Resource


var owner: Node3D # The ScatterShape node it's attached to.


func _init():
	resource_local_to_scene = true


# point must be in global space
func is_point_inside(point: Vector3) -> bool:
	return false


# Returns an array of Vector3. This should contain enough points to compute
# a bounding box for the given shape.
func get_corners_global() -> Array:
	return []


# Returns a copy of this shape.
# TODO: check later when Godot4 enters beta if we can get rid of this and use
# the built-in duplicate() method properly.
func get_copy() -> Resource:
	return null
