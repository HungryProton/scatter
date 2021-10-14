extends Node


static func curve_to_string(curve: Curve) -> String:
	if not curve:
		return ""

	var dict = {}
	dict.points = []
	for i in curve.get_point_count():
		var p := {}
		p["lm"] = curve.get_point_left_mode(i)
		p["lt"] = curve.get_point_left_tangent(i)
		var pos = curve.get_point_position(i)
		p["x"] = pos.x
		p["y"] = pos.y
		p["rm"] = curve.get_point_right_mode(i)
		p["rt"] = curve.get_point_right_tangent(i)
		dict.points.push_back(p)

	dict.parameters = {
		"min": curve.get_min_value(),
		"max": curve.get_max_value(),
		"res": curve.get_bake_resolution(),
	}

	return JSON.print(dict)


static func string_to_curve(string: String) -> Curve:
	var curve = Curve.new()
	if not string or string.empty():
		return curve

	var json_result = JSON.parse(string)
	if json_result.error != OK:
		return curve

	var dict: Dictionary = json_result.result

	curve.max_value = dict.parameters.max
	curve.min_value = dict.parameters.min
	curve.bake_resolution = dict.parameters.res

	for p in dict.points:
		curve.add_point(Vector2(p.x, p.y), p.lt, p.rt, p.lm, p.rm)

	return curve


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
