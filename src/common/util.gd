@tool
extends RefCounted

# Create a new with as many surfaces as inputs
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
