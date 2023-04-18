@tool
extends "gizmo_handler.gd"


const ProtonScatter := preload("res://addons/proton_scatter/src/scatter.gd")
const ProtonScatterShape := preload("res://addons/proton_scatter/src/scatter_shape.gd")
const ProtonScatterEventHelper := preload("res://addons/proton_scatter/src/common/event_helper.gd")
const PathPanel := preload("./components/path_panel.gd")

var _gizmo_panel: PathPanel
var _event_helper: ProtonScatterEventHelper


func get_handle_name(_gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> String:
	return "Path point"


func get_handle_value(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> Variant:
	var shape: ProtonScatterPathShape = gizmo.get_node_3d().shape
	return shape.get_copy()


func set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if not _gizmo_panel.is_select_mode_enabled():
		return

	var shape_node: ProtonScatterShape = gizmo.get_node_3d()
	var curve: Curve3D = shape_node.shape.curve
	var point_count: int = curve.get_point_count()
	var curve_index := handle_id
	var previous_handle_position: Vector3

	if not secondary:
		previous_handle_position = curve.get_point_position(curve_index)
	else:
		curve_index = int(handle_id / 2)
		previous_handle_position = curve.get_point_position(curve_index)
		if handle_id % 2 == 0:
			previous_handle_position += curve.get_point_in(curve_index)
		else:
			previous_handle_position += curve.get_point_out(curve_index)

	var click_world_position := _intersect_with(shape_node, camera, screen_pos, previous_handle_position)
	var point_local_position: Vector3 = shape_node.get_global_transform().affine_inverse() * click_world_position

	if not secondary:
		# Main curve point moved
		curve.set_point_position(handle_id, point_local_position)
	else:
		# In out handle moved
		var mirror_angle := _gizmo_panel.is_mirror_angle_enabled()
		var mirror_length := _gizmo_panel.is_mirror_length_enabled()

		var point_origin = curve.get_point_position(curve_index)
		var in_out_position = point_local_position - point_origin
		var mirror_position = -in_out_position

		if handle_id % 2 == 0:
			curve.set_point_in(curve_index, in_out_position)
			if mirror_angle:
				if not mirror_length:
					mirror_position = curve.get_point_out(curve_index).length() * -in_out_position.normalized()
				curve.set_point_out(curve_index, mirror_position)
		else:
			curve.set_point_out(curve_index, in_out_position)
			if mirror_angle:
				if not mirror_length:
					mirror_position = curve.get_point_in(curve_index).length() * -in_out_position.normalized()
				curve.set_point_in(curve_index, mirror_position)

	shape_node.update_gizmos()


func commit_handle(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var shape_node: ProtonScatterShape = gizmo.get_node_3d()

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

	# Force the path panel to appear when the scatter shape type is changed
	# from the inspector.
	if is_selected(gizmo):
		_gizmo_panel.selection_changed([gizmo.get_node_3d()])

	var shape_node: ProtonScatterShape = gizmo.get_node_3d()
	var shape: ProtonScatterPathShape = shape_node.shape

	if not shape:
		return

	var curve: Curve3D = shape.curve
	if not curve or curve.get_point_count() == 0:
		return

	# ------ Common stuff ------
	var points := curve.tessellate(4, 8)
	var points_2d := PackedVector2Array()
	for p in points:
		points_2d.push_back(Vector2(p.x, p.z))

	var line_material: StandardMaterial3D = plugin.get_material("primary_top", gizmo)
	var mesh_material: StandardMaterial3D = plugin.get_material("inclusive", gizmo)
	if shape_node.negative:
		mesh_material = plugin.get_material("exclusive", gizmo)

	# ------ Main line along the path curve ------
	var lines := PackedVector3Array()
	var lines_count := points.size() - 1

	for i in lines_count:
		lines.append(points[i])
		lines.append(points[i + 1])

	gizmo.add_lines(lines, line_material)
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

	gizmo.add_handles(main_handles, plugin.get_material("primary_handle", gizmo), ids)
	gizmo.add_handles(in_out_handles, plugin.get_material("secondary_handle", gizmo), ids, false, true)

	if is_selected(gizmo):
		gizmo.add_lines(handle_lines, plugin.get_material("secondary_top", gizmo))

	# -------- Visual when lock to plane is enabled --------
	if _gizmo_panel.is_lock_to_plane_enabled() and is_selected(gizmo):
		var bounds = shape.get_bounds()
		var aabb = AABB(bounds.min, bounds.size).grow(shape.thickness / 2.0)

		var width: float = aabb.size.x
		var length: float = aabb.size.z
		var plane_center: Vector3 = bounds.center
		plane_center.y = 0.0

		var plane_mesh := PlaneMesh.new()
		plane_mesh.set_size(Vector2(width, length))
		plane_mesh.set_center_offset(plane_center)

		gizmo.add_mesh(plane_mesh, plugin.get_material("tertiary", gizmo))

		var plane_lines := PackedVector3Array()
		var corners = [
			Vector3(-width, 0, -length),
			Vector3(-width, 0, length),
			Vector3(width, 0, length),
			Vector3(width, 0, -length),
			Vector3(-width, 0, -length),
		]
		for i in corners.size() - 1:
			plane_lines.push_back(corners[i] * 0.5 + plane_center)
			plane_lines.push_back(corners[i + 1] * 0.5 + plane_center)

		gizmo.add_lines(plane_lines, plugin.get_material("secondary_top", gizmo))

	# ----- Mesh representing the inside part of the path -----
	if shape.closed:
		var indices = Geometry2D.triangulate_polygon(points_2d)
		if indices.is_empty():
			indices =  Geometry2D.triangulate_delaunay(points_2d)

		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in indices:
			var p = points_2d[index]
			st.add_vertex(Vector3(p.x, 0.0, p.y))

		var mesh = st.commit()
		gizmo.add_mesh(mesh, mesh_material)

	# ------ Mesh representing path thickness ------
	if shape.thickness > 0 and points.size() > 1:

		# ____ TODO ____ : check if this whole section could be replaced by
		# Geometry2D.expand_polyline, or an extruded capsule along the path

		## Main path mesh
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

		for i in points.size() - 1:
			var p1: Vector3 = points[i]
			var p2: Vector3 = points[i + 1]

			var normal = (p2 - p1).cross(Vector3.UP).normalized()
			var offset = normal * shape.thickness * 0.5

			st.add_vertex(p1 - offset)
			st.add_vertex(p1 + offset)

		## Add the last missing two triangles from the loop above
		var p1: Vector3 = points[-1]
		var p2: Vector3 = points[-2]
		var normal = (p1 - p2).cross(Vector3.UP).normalized()
		var offset = normal * shape.thickness * 0.5

		st.add_vertex(p1 - offset)
		st.add_vertex(p1 + offset)

		var mesh := st.commit()
		gizmo.add_mesh(mesh, mesh_material)

		## Rounded cap (start)
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var center = points[0]
		var next = points[1]
		normal = (center - next).cross(Vector3.UP).normalized()

		for i in 12:
			st.add_vertex(center)
			st.add_vertex(center + normal * shape.thickness * 0.5)
			normal = normal.rotated(Vector3.UP, PI / 12)
			st.add_vertex(center + normal * shape.thickness * 0.5)

		mesh = st.commit()
		gizmo.add_mesh(mesh, mesh_material)

		## Rounded cap (end)
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		center = points[-1]
		next = points[-2]
		normal = (next - center).cross(Vector3.UP).normalized()

		for i in 12:
			st.add_vertex(center)
			st.add_vertex(center + normal * shape.thickness * 0.5)
			normal = normal.rotated(Vector3.UP, -PI / 12)
			st.add_vertex(center + normal * shape.thickness * 0.5)

		mesh = st.commit()
		gizmo.add_mesh(mesh, mesh_material)


func forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> bool:
	if not _event_helper:
		_event_helper = ProtonScatterEventHelper.new()

	_event_helper.feed(event)

	if not event is InputEventMouseButton:
		return false

	if not _event_helper.is_key_just_pressed(MOUSE_BUTTON_LEFT): # Can't use just_released here
		return false

	var shape_node: ProtonScatterShape = _gizmo_panel.shape_node
	if not shape_node:
		return false

	if not shape_node.shape or not shape_node.shape is ProtonScatterPathShape:
		return false

	var shape: ProtonScatterPathShape = shape_node.shape

	# In select mode, the set_handle and commit_handle functions take over.
	if _gizmo_panel.is_select_mode_enabled():
		return false

	var click_world_position := _intersect_with(shape_node, viewport_camera, event.position)
	var point_local_position: Vector3 = shape_node.get_global_transform().affine_inverse() * click_world_position

	if _gizmo_panel.is_create_mode_enabled():
		shape.create_point(point_local_position) # TODO: add undo redo
		shape_node.update_gizmos()
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


func _edit_path(shape_node: ProtonScatterShape, restore: ProtonScatterPathShape) -> void:
	shape_node.shape.curve = restore.curve.duplicate()
	shape_node.shape.thickness = restore.thickness
	shape_node.update_gizmos()


func _intersect_with(path: ProtonScatterShape, camera: Camera3D, screen_point: Vector2, handle_position_local = null) -> Vector3:
	# Get the ray data
	var from = camera.project_ray_origin(screen_point)
	var dir = camera.project_ray_normal(screen_point)
	var gt = path.get_global_transform()

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
		var t = Transform3D(gt)
		var a = t.basis.x
		var b = t.basis.z
		var c = a + b
		var o = t.origin
		var plane = Plane(a + o, b + o, c + o)
		var result = plane.intersects_ray(from, dir)
		if result != null:
			return result

	# Default case (similar to the built in Path3D node)
	var origin: Vector3
	if handle_position_local:
		origin = gt * handle_position_local
	else:
		origin = path.get_global_transform().origin

	var plane = Plane(dir, origin)
	var res = plane.intersects_ray(from, dir)
	if res != null:
		return res

	return origin

