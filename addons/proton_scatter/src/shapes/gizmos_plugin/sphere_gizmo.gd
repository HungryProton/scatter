@tool
extends "gizmo_handler.gd"

# 3D Gizmo for the Sphere shape. Draws three circle on each axis to represent
# a sphere, displays one handle on the size to control the radius.
#
# (handle_id is ignored in every function since there's a single handle)

const SphereShape = preload("../sphere_shape.gd")


func get_handle_name(_gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> String:
	return "Radius"


func get_handle_value(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> Variant:
	return gizmo.get_node_3d().shape.radius


func set_handle(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var shape_node = gizmo.get_node_3d()
	var gt := shape_node.get_global_transform()
	var gt_inverse := gt.affine_inverse()
	var origin := gt.origin

	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_to = ray_from + camera.project_ray_normal(screen_pos) * 4096
	var points = Geometry3D.get_closest_points_between_segments(origin, (Vector3.LEFT * 4096) * gt_inverse, ray_from, ray_to)
	shape_node.shape.radius = origin.distance_to(points[0])


func commit_handle(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var shape: SphereShape = gizmo.get_node_3d().shape
	if cancel:
		shape.radius = restore
		return

	_undo_redo.create_action("Set ScatterShape Radius")
	_undo_redo.add_undo_method(self, "_set_radius", shape, restore)
	_undo_redo.add_do_method(self, "_set_radius", shape, shape.radius)
	_undo_redo.commit_action()


func redraw(plugin: EditorNode3DGizmoPlugin, gizmo: EditorNode3DGizmo):
	gizmo.clear()

	var scatter_shape = gizmo.get_node_3d()
	var shape: SphereShape = scatter_shape.shape

	### Draw the 3 circles on each axis to represent the sphere
	var lines = PackedVector3Array()
	var lines_material := plugin.get_material("primary_top", gizmo)
	var steps = 32 # TODO: Update based on sphere radius maybe ?
	var step_angle = 2 * PI / steps
	var radius = shape.radius

	for i in steps:
		lines.append(Vector3(cos(i * step_angle), 0.0, sin(i * step_angle)) * radius)
		lines.append(Vector3(cos((i + 1) * step_angle), 0.0, sin((i + 1) * step_angle)) * radius)

	if is_selected(gizmo):
		for i in steps:
			lines.append(Vector3(cos(i * step_angle), sin(i * step_angle), 0.0) * radius)
			lines.append(Vector3(cos((i + 1) * step_angle), sin((i + 1) * step_angle), 0.0) * radius)

		for i in steps:
			lines.append(Vector3(0.0, cos(i * step_angle), sin(i * step_angle)) * radius)
			lines.append(Vector3(0.0, cos((i + 1) * step_angle), sin((i + 1) * step_angle)) * radius)

	gizmo.add_lines(lines, lines_material)
	gizmo.add_collision_segments(lines)

	### Draw the handle
	var handles := PackedVector3Array()
	var handles_ids := PackedInt32Array()
	var handles_material := plugin.get_material("default_handle", gizmo)

	var handle_position: Vector3 = Vector3.LEFT * radius
	handles.push_back(handle_position)

	gizmo.add_handles(handles, handles_material, handles_ids)

	### Fills the sphere inside
	var mesh = SphereMesh.new()
	mesh.height = shape.radius * 2.0
	mesh.radius = shape.radius
	var mesh_material: StandardMaterial3D
	if scatter_shape.negative:
		mesh_material = plugin.get_material("exclusive", gizmo)
	else:
		mesh_material = plugin.get_material("inclusive", gizmo)
	gizmo.add_mesh(mesh, mesh_material)


func _set_radius(sphere: SphereShape, radius: float) -> void:
	if sphere:
		sphere.radius = radius
