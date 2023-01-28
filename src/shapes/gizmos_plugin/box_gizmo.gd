@tool
extends "gizmo_handler.gd"

# 3D Gizmo for the Box shape.


func get_handle_name(_gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> String:
	return "Box Size"


func get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool) -> Variant:
	return gizmo.get_node_3d().shape.size


func set_handle(gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if handle_id < 0 or handle_id > 2:
		return

	var axis := Vector3.ZERO
	axis[handle_id] = 1.0 # handle 0:x, 1:y, 2:z

	var shape_node = gizmo.get_node_3d()
	var gt := shape_node.get_global_transform()
	var gt_inverse := gt.affine_inverse()

	var origin := gt.origin
	var drag_axis := (axis * 4096) * gt_inverse
	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_to = ray_from + camera.project_ray_normal(screen_pos) * 4096

	var points = Geometry3D.get_closest_points_between_segments(origin, drag_axis, ray_from, ray_to)

	var size = shape_node.shape.size
	size -= axis * size
	var dist = origin.distance_to(points[0]) * 2.0
	size += axis * dist

	shape_node.shape.size = size


func commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var shape: ProtonScatterBoxShape = gizmo.get_node_3d().shape
	if cancel:
		shape.size = restore
		return

	_undo_redo.create_action("Set ScatterShape size")
	_undo_redo.add_undo_method(self, "_set_size", shape, restore)
	_undo_redo.add_do_method(self, "_set_size", shape, shape.size)
	_undo_redo.commit_action()


func redraw(plugin: EditorNode3DGizmoPlugin, gizmo: EditorNode3DGizmo):
	gizmo.clear()
	var scatter_shape = gizmo.get_node_3d()
	var shape: ProtonScatterBoxShape = scatter_shape.shape

	### Draw the Box lines
	var lines = PackedVector3Array()
	var lines_material := plugin.get_material("primary_top", gizmo)
	var half_size = shape.size * 0.5

	var corners := [
		[ # Bottom square
			Vector3(-1, -1, -1),
			Vector3(-1, -1, 1),
			Vector3(1, -1, 1),
			Vector3(1, -1, -1),
			Vector3(-1, -1, -1),
		],
		[ # Top square
			Vector3(-1, 1, -1),
			Vector3(-1, 1, 1),
			Vector3(1, 1, 1),
			Vector3(1, 1, -1),
			Vector3(-1, 1, -1),
		],
		[ # Vertical lines
			Vector3(-1, -1, -1),
			Vector3(-1, 1, -1),
		],
		[
			Vector3(-1, -1, 1),
			Vector3(-1, 1, 1),
		],
		[
			Vector3(1, -1, 1),
			Vector3(1, 1, 1),
		],
		[
			Vector3(1, -1, -1),
			Vector3(1, 1, -1),
		]
	]

	var block_count = corners.size()
	if not is_selected(gizmo):
		block_count = 1

	for i in block_count:
		var block = corners[i]
		for j in block.size() - 1:
			lines.push_back(block[j] * half_size)
			lines.push_back(block[j + 1] * half_size)

	gizmo.add_lines(lines, lines_material)
	gizmo.add_collision_segments(lines)

	### Fills the box inside
	var mesh = BoxMesh.new()
	mesh.size = shape.size

	var mesh_material: StandardMaterial3D
	if scatter_shape.negative:
		mesh_material = plugin.get_material("exclusive", gizmo)
	else:
		mesh_material = plugin.get_material("inclusive", gizmo)

	gizmo.add_mesh(mesh, mesh_material)

	### Draw the handles, one for each axis
	var handles := PackedVector3Array()
	var handles_ids := PackedInt32Array()
	var handles_material := plugin.get_material("default_handle", gizmo)

	handles.push_back(Vector3.RIGHT * shape.size.x * 0.5)
	handles.push_back(Vector3.UP * shape.size.y * 0.5)
	handles.push_back(Vector3.BACK * shape.size.z * 0.5)

	gizmo.add_handles(handles, handles_material, handles_ids)


func _set_size(box: ProtonScatterBoxShape, size: Vector3) -> void:
	if box:
		box.size = size
