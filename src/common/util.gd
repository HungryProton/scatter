@tool
extends RefCounted


# Create a new Mesh with as many surfaces as inputs
static func create_mesh_from(mesh_instances: Array) -> Mesh:
	var total_surfaces = 0
	var array_mesh = ArrayMesh.new()

	for mi in mesh_instances:
		var mesh: Mesh = mi.mesh
		var surface_count = mesh.get_surface_count()

		for i in surface_count:
			var arrays = mesh.surface_get_arrays(i)
			var length = arrays[ArrayMesh.ARRAY_VERTEX].size()

			for j in length:
				var pos: Vector3 = arrays[ArrayMesh.ARRAY_VERTEX][j]
				pos = mi.transform.xform(pos)
				arrays[ArrayMesh.ARRAY_VERTEX][j] = pos

			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

			# Retrieve the material on the MeshInstance first, if none is defined,
			# use the one from the mesh resource.
			var material = mi.get_surface_material(i)
			if not material:
				material = mesh.surface_get_material(i)
			array_mesh.surface_set_material(total_surfaces, material)

			total_surfaces += 1

	return array_mesh


static func get_node_by_class_path(node: Node, class_path: Array) -> Node:
	var res: Node

	var stack := []
	var depths := []

	var first = class_path[0]
	for c in node.get_children():
		if c.get_class() == first:
			stack.push_back(c)
			depths.push_back(0)

	if stack.is_empty(): return res

	var max_ = class_path.size()-1

	while stack:
		var d = depths.pop_front()
		var n = stack.pop_front()

		if d > max_:
			continue
		if n.get_class() == class_path[d]:
			if d == max_:
				res = n
				return res
			for c in n.get_children():
				stack.push_back(c)
				depths.push_back(d+1)

	return res


static func get_position_and_normal_at(curve: Curve3D, offset: float) -> Array:
	if not curve:
		return []

	var pos: Vector3 = curve.interpolate_baked(offset)
	var normal := Vector3.ZERO

	var pos1
	if offset + curve.get_bake_interval() < curve.get_baked_length():
		pos1 = curve.interpolate_baked(offset + curve.get_bake_interval())
		normal = (pos1 - pos)
	else:
		pos1 = curve.interpolate_baked(offset - curve.get_bake_interval())
		normal = (pos - pos1)

	return [pos, normal]
