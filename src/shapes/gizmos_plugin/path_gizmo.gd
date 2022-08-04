@tool
extends "gizmo_handler.gd"


const ScatterShape = preload("../../scatter_shape.gd")
const PathShape = preload("../path_shape.gd")
const PathPanel = preload("./components/path_panel.gd")
const EventUtil = preload("../../common/event_util.gd")

var _gizmo_panel: PathPanel
var _event_util: EventUtil


func get_handle_name(_gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> String:
	return "Path point"


func get_handle_value(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> Variant:
	var shape: PathShape = gizmo.get_spatial_node().shape
	return shape.get_copy()


func set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var shape_node: ScatterShape = gizmo.get_spatial_node()
	var curve: Curve3D = shape_node.shape.curve
	var point_count: int = curve.get_point_count()

	var click_world_position := _intersect_with(shape_node, camera, screen_pos)
	var point_local_position: Vector3 = shape_node.get_global_transform().affine_inverse() * click_world_position

	if not secondary:
		# Main curve point moved
		curve.set_point_position(handle_id, point_local_position)
	else:
		# In out handle moved
		var align_handles = Input.is_key_pressed(KEY_SHIFT)
		var index = int(handle_id / 2)
		var point_origin = curve.get_point_position(index)
		var in_out_position = point_local_position - point_origin

		if handle_id % 2 == 0:
			curve.set_point_in(index, in_out_position)
			if align_handles:
				curve.set_point_out(index, -in_out_position)
		else:
			curve.set_point_out(index, in_out_position)
			if align_handles:
				curve.set_point_in(index, -in_out_position)

	shape_node.update_gizmos()


func commit_handle(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var shape_node: ScatterShape = gizmo.get_spatial_node()

	if cancel:
		_edit_path(shape_node, restore)
	else:
		_undo_redo.create_action("Edit ScatterShape Path")
		_undo_redo.add_undo_method(self, "_edit_path", shape_node, restore)
		_undo_redo.add_do_method(self, "_edit_path", shape_node, shape_node.shape.get_copy())
		_undo_redo.commit_action()

	shape_node.update_gizmos()


func redraw(plugin: EditorNode3DGizmoPlugin, gizmo: EditorNode3DGizmo):
	gizmo.clear()

	var shape: PathShape = gizmo.get_spatial_node().shape
	if not shape:
		return

	var curve: Curve3D = shape.curve
	if not curve or curve.get_point_count() == 0:
		return

	# ------ Main line along the path curve ------

	var lines := PackedVector3Array()
	var points := curve.tessellate(4, 8)
	var lines_count := points.size() - 1

	for i in lines_count:
		lines.append(points[i])
		lines.append(points[i + 1])

	gizmo.add_lines(lines, plugin.get_material("line", gizmo))
	gizmo.add_collision_segments(lines)

	# ------ Draw handles ------

	var main_handles := PackedVector3Array()
	var in_out_handles := PackedVector3Array()
	var handle_lines := PackedVector3Array()
	var ids := PackedInt32Array() # Stays empty on purpose

	for i in curve.get_point_count():
		var point_pos = curve.get_point_position(i)
		var point_in = curve.get_point_in(i) + point_pos
		var point_out = curve.get_point_out(i) + point_pos

		handle_lines.push_back(point_pos)
		handle_lines.push_back(point_in)
		handle_lines.push_back(point_pos)
		handle_lines.push_back(point_out)

		in_out_handles.push_back(point_in)
		in_out_handles.push_back(point_out)
		main_handles.push_back(point_pos)

	gizmo.add_handles(main_handles, plugin.get_material("main_handle", gizmo), ids)
	gizmo.add_handles(in_out_handles, plugin.get_material("secondary_handle", gizmo), ids, false, true)
	gizmo.add_lines(handle_lines, plugin.get_material("handle_line", gizmo))

	# ----- Mesh representing the inside part of the path -----
	if shape.closed:
		pass


	# ------ Mesh representing path width ------
	if shape.width <= 0:
		return

	if points.size() < 2:
		return

	## Main path mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in points.size() - 1:
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[i + 1]

		var normal = (p2 - p1).cross(Vector3.UP).normalized()
		var offset = normal * shape.width * 0.5

		st.add_vertex(p1 - offset)
		st.add_vertex(p1 + offset)

	## Add the last missing two triangles from the loop above
	var p1: Vector3 = points[-1]
	var p2: Vector3 = points[-2]
	var normal = (p1 - p2).cross(Vector3.UP).normalized()
	var offset = normal * shape.width * 0.5

	st.add_vertex(p1 - offset)
	st.add_vertex(p1 + offset)

	var mesh := st.commit()
	gizmo.add_mesh(mesh, plugin.get_material("mesh", gizmo))

	## Rounded cap (start)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center = points[0]
	var next = points[1]
	normal = (center - next).cross(Vector3.UP).normalized()

	for i in 16:
		st.add_vertex(center)
		st.add_vertex(center + normal * shape.width * 0.5)
		normal = normal.rotated(Vector3.UP, PI / 16)
		st.add_vertex(center + normal * shape.width * 0.5)

	mesh = st.commit()
	gizmo.add_mesh(mesh, plugin.get_material("mesh", gizmo))

	## Rounded cap (end)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	center = points[-1]
	next = points[-2]
	normal = (next - center).cross(Vector3.UP).normalized()

	for i in 16:
		st.add_vertex(center)
		st.add_vertex(center + normal * shape.width * 0.5)
		normal = normal.rotated(Vector3.UP, -PI / 16)
		st.add_vertex(center + normal * shape.width * 0.5)

	mesh = st.commit()
	gizmo.add_mesh(mesh, plugin.get_material("mesh", gizmo))


func forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if not _event_util:
		_event_util = EventUtil.new()

	_event_util.feed(event)

	if not event is InputEventMouseButton:
		return false

	if not _event_util.is_key_just_released(MOUSE_BUTTON_LEFT):
		return false

	var shape_node: ScatterShape = _gizmo_panel.shape_node
	if not shape_node:
		return false

	var shape: PathShape = shape_node.shape
	if not shape:
		return false

	# In select mode, the set_handle and commit_handle functions take over.
	if _gizmo_panel.is_select_mode_enabled():
		return false

	var click_world_position := _intersect_with(shape_node, viewport_camera, event.position)
	var point_local_position: Vector3 = shape_node.get_global_transform().affine_inverse() * click_world_position

	if _gizmo_panel.is_create_mode_enabled():
		shape.create_point(point_local_position)
		shape_node.update_gizmos() # TODO: add undo redo
		return true

	elif _gizmo_panel.is_delete_mode_enabled():
		var index = shape.get_closest_to(point_local_position)
		if index != -1:
			shape.remove_point(index) # TODO: add undo redo
			shape_node.update_gizmos()
			return true

	return false


func set_gizmo_panel(panel: PathPanel) -> void:
	_gizmo_panel = panel


func _edit_path(shape_node: ScatterShape, restore: PathShape) -> void:
	shape_node.shape.curve = restore.curve.duplicate()
	shape_node.shape.width = restore.width
	shape_node.update_gizmos()


func _intersect_with(path: ScatterShape, camera: Camera3D, screen_point: Vector2, handle_position = null) -> Vector3:
	# Get the ray data
	var from = camera.project_ray_origin(screen_point)
	var dir = camera.project_ray_normal(screen_point)

	# Snap to collider enabled
	if _gizmo_panel.is_snap_to_colliders_enabled():
		var space_state: PhysicsDirectSpaceState3D = path.get_world_3d().get_direct_space_state()
		var parameters := PhysicsRayQueryParameters3D.new()
		parameters.from = from
		parameters.to = from + (dir * 2048)
		var hit := space_state.intersect_ray(parameters)
		if not hit.is_empty():
			return hit.position

	# Lock to plane enabled
	if _gizmo_panel.is_lock_to_plane_enabled():
		var t = path.get_global_transform()
		var a = t.basis.x
		var b = t.basis.z
		var c = a + b
		var o = t.origin
		var plane = Plane(a + o, b + o, c + o)
		return plane.intersects_ray(from, dir)

	# Default case (similar to the built in Path3D node)
	var origin: Vector3
	if handle_position:
		origin = handle_position
	else:
		origin = path.get_global_transform().origin

	var plane = Plane(dir, origin)
	return plane.intersects_ray(from, dir)

