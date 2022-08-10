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
const BaseShape := preload("../shapes/base_shape.gd")
const Bounds := preload("../common/bounds.gd")


class DomainShapeInfo:
	var transform: Transform3D
	var shape: BaseShape

	func is_point_inside(point: Vector3) -> bool:
		return shape.is_point_inside(point, transform)

	func get_corners_global() -> Array:
		return shape.get_corners_global(transform)


var root: Node3D:
	set(val):
		root = val
		space_state = null
		if root:
			space_state = root.get_world_3d().get_direct_space_state()

var space_state: PhysicsDirectSpaceState3D
var inclusive_shapes: Array[DomainShapeInfo]
var exclusive_shapes: Array[DomainShapeInfo]
var bounds: Bounds = Bounds.new()


func is_empty() -> bool:
	return inclusive_shapes.is_empty()


# If a point is in an exclusion shape, returns false
# If a point is in an inclusion shape (but not in an exclusion one), returns true
# If a point is in neither, returns false
func is_point_inside(point: Vector3) -> bool:
	for s in exclusive_shapes:
		if s.is_point_inside(point):
			return false

	for s in inclusive_shapes:
		if s.is_point_inside(point):
			return true

	return false

# Recursively find all ScatterShape nodes under the provided root. In case of
# nested Scatter nodes, shapes under these other Scatter nodes will be ignored
func discover_shapes(root_node: Node3D) -> void:
	root = root_node
	inclusive_shapes.clear()
	exclusive_shapes.clear()
	var root_type = root.get_script() # Can't preload the scatter script here (cyclic dependency)
	for c in root.get_children():
		_discover_shapes_recursive(c, root_type)
	compute_bounds()


func compute_bounds() -> void:
	bounds.clear()
	for info in inclusive_shapes:
		for point in info.get_corners_global():
			bounds.feed(point)

	bounds.compute_bounds()


func get_global_transform() -> Transform3D:
	return root.get_global_transform()


func get_local_transform() -> Transform3D:
	return root.get_transform()


func get_edges() -> Array[Curve3D]:
	return [] #TODO


func get_copy():
	var copy = get_script().new()

	copy.root = root
	copy.space_state = space_state
	copy.bounds = bounds

	for s in inclusive_shapes:
		var s_copy = DomainShapeInfo.new()
		s_copy.transform = s.transform
		s_copy.shape = s.shape.get_copy()
		copy.inclusive_shapes.push_back(s_copy)

	for s in exclusive_shapes:
		var s_copy = DomainShapeInfo.new()
		s_copy.transform = s.transform
		s_copy.shape = s.shape.get_copy()
		copy.exclusive_shapes.push_back(s_copy)

	return copy


func _discover_shapes_recursive(node: Node3D, type_to_ignore) -> void:
	if node is type_to_ignore: # Ignore shapes under nested Scatter nodes
		return

	if node is ScatterShape and node.shape != null:
		var info := DomainShapeInfo.new()
		info.transform = node.get_global_transform()
		info.shape = node.shape

		if node.exclusive:
			exclusive_shapes.push_back(info)
		else:
			inclusive_shapes.push_back(info)

	for c in node.get_children():
		_discover_shapes_recursive(c, type_to_ignore)
