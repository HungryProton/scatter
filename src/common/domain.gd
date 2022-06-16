@tool
extends RefCounted

# A domain is the complete area where transforms can (and can't) be placed.
# A Scatter node has one single domain, a domain has one or more shape nodes.
#
# It's the combination of every shape defined under a Scatter node, grouped in
# a single class that exposes utility functions (check if a point is inside, or
# along the surface etc).
#
# An instance of this class is passed to the modifiers during a rebuild.


const ScatterShape := preload("../scatter_shape.gd")
const Bounds := preload("../common/bounds.gd")

var bounds: Bounds = Bounds.new()

var _root: Node3D
var _shapes: Dictionary


func is_empty() -> bool:
	return _shapes.inclusive.is_empty()


# If a point is in an exclusion shape, returns false
# If a point is in an inclusion shape (but not in an exclusion one), returns true
# If a point is in neither, returns false
func is_point_inside(point: Vector3) -> bool:
	for s in _shapes.exclusive:
		if s.is_point_inside(point):
			return false

	for s in _shapes.inclusive:
		if s.is_point_inside(point):
			return true

	return false


func get_global_transform() -> Transform3D:
	return _root.get_global_transform()


func get_local_transform() -> Transform3D:
	return _root.get_transform()


# Recursively find all ScatterShape nodes under the provided root. In case of
# nested Scatter nodes, shapes under these other Scatter nodes will be ignored
func discover_shapes(root: Node3D) -> void:
	_root = root
	_shapes = {
		inclusive = [],
		exclusive = []
	}
	var root_type = root.get_script() # Can't preload the scatter script here (cyclic dependency)
	for c in root.get_children():
		_discover_shapes_recursive(c, root_type)
	compute_bounds(root)


func compute_bounds(root: Node3D) -> void:
	if _shapes.is_empty():
		discover_shapes(root)
		return

	bounds.clear()
	for node in _shapes.inclusive:
		for point in node.shape.get_corners_global():
			bounds.feed(point)

	bounds.compute_bounds()


func _discover_shapes_recursive(node: Node3D, type_to_ignore) -> void:
	if node is type_to_ignore: # Ignore shapes under nested Scatter nodes
		return

	if node is ScatterShape:
		if node.exclusive:
			_shapes.exclusive.push_back(node)
		else:
			_shapes.inclusive.push_back(node)

	for c in node.get_children():
		_discover_shapes_recursive(c, type_to_ignore)
