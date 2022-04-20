tool
extends EditorSpatialGizmoPlugin


class PointState:
	var point_count: int
	var position: Vector3
	var version: int

var editor_plugin: EditorPlugin setget set_editor_plugin
var options setget _set_options

var _namespace = load(_get_root_folder() + "/src/core/namespace.gd").new()
var _axis_mesh: ArrayMesh
var _selected
var _old_position: Vector3
var _camera: Camera
var _previous_state := PointState.new()
var _is_forcing_projection := false
var _undo: UndoRedo


func _init():
	create_custom_material("path", Color(1, 0, 0))
	create_custom_material("grid", Color(1, 0.7, 0))
	create_custom_material("handle_lines", Color(0.1, 0.1, 0.1))
	create_handle_material("handles")

	var in_out_icon = load(_get_root_folder() + "/icons/square_handle.svg")
	create_custom_handle_material("square_handle", in_out_icon)


func get_name() -> String:
	return "ScatterPath"


func has_gizmo(node):
	return node is _namespace.ScatterPath


func get_handle_name(_gizmo: EditorSpatialGizmo, index: int) -> String:
	return "Handle " + String(index)


func get_handle_value(gizmo: EditorSpatialGizmo, index: int):
	var path = gizmo.get_spatial_node()
	if not path:
		return null

	var curve: Curve3D = path.get_curve()
	if not curve:
		return null

	var count = curve.get_point_count()
	var p_in := false
	var p_out := false

	if index >= count:
		var i = index - count
		index = int(i / 2)
		p_in = (i % 2 == 0)
		p_out = !p_in

	var data: Dictionary = _get_point_data(path.curve, index)

	_old_position = data.pos
	if p_in:
		_old_position += data.in
	elif p_out:
		_old_position += data.out

	return data


# Automatically called when a handle is moved around.
func set_handle(gizmo: EditorSpatialGizmo, index: int, camera: Camera, point: Vector2) -> void:
	var path = gizmo.get_spatial_node()
	if not path:
		return

	path.is_moving = true
	var local_pos

	if options and options.snap_to_colliders():
		local_pos = _intersect_with_colliders(path, camera, point)

	elif options and options.lock_to_plane():
		local_pos = _intersect_with_plane(path, camera, point)

	else:
		local_pos = _intersect_screen_space(path, camera, point)

	if not local_pos:
		return

	local_pos = path.to_local(local_pos)
	var count = path.curve.get_point_count()
	var shift_pressed = Input.is_key_pressed(KEY_SHIFT)

	if shift_pressed and index < count:
		index = (index * 2) + count + 1  # Force select the out handle

	if index < count:
		path.curve.set_point_position(index, local_pos)
	else:
		var i = (index - count)
		var p_index = int(i / 2)
		var base = path.curve.get_point_position(p_index)
		if i % 2 == 0:
			path.curve.set_point_in(p_index, local_pos - base)
			if shift_pressed:
				path.curve.set_point_out(p_index, -(local_pos - base))
		else:
			path.curve.set_point_out(p_index, local_pos - base)
			if shift_pressed:
				path.curve.set_point_in(p_index, -(local_pos - base))

	redraw(gizmo)


# Handle Undo / Redo after a handle was moved.
func commit_handle(gizmo: EditorSpatialGizmo, index: int, restore, _cancel: bool = false) -> void:
	var path = gizmo.get_spatial_node()
	if not path:
		return

	var count = path.curve.get_point_count()

	if index >= count:
		index = int((index - count) / 2)

	_undo.create_action("Moved Path Point")
	_undo.add_undo_method(self, "_set_point", path, restore)
	_undo.add_do_method(self, "_set_point", path, _get_point_data(path.curve, index))
	_undo.commit_action()

	path.is_moving = false
	path.update()


func redraw(gizmo: EditorSpatialGizmo):
	if not gizmo:
		return

	gizmo.clear()
	var path = gizmo.get_spatial_node()
	if not path:
		return

	if not _selected or path != _selected:
		_draw_path(gizmo)
		return

	_draw_handles(gizmo)
	_draw_path(gizmo)
	if options and options.lock_to_plane():
		_draw_grid(gizmo)


func force_redraw():
	if _selected and is_instance_valid(_selected):
		_selected.update_gizmo()


func create_custom_handle_material(name, icon: Texture, color := Color.white):
	var handle_material = SpatialMaterial.new()
	handle_material.render_priority = 100

	handle_material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	handle_material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	handle_material.set_flag(SpatialMaterial.FLAG_USE_POINT_SIZE, true)
	handle_material.set_flag(SpatialMaterial.FLAG_ALBEDO_FROM_VERTEX_COLOR, true)
	handle_material.set_flag(SpatialMaterial.FLAG_SRGB_VERTEX_COLOR, true)
	handle_material.set_flag(SpatialMaterial.FLAG_DISABLE_DEPTH_TEST, true)
	handle_material.set_point_size(icon.get_width())
	handle_material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, icon)
	handle_material.set_albedo(color)

	add_material(name, handle_material)


func create_custom_material(name, color := Color.white):
	var material = SpatialMaterial.new()
	material.render_priority = 100

	material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	material.set_flag(SpatialMaterial.FLAG_ALBEDO_FROM_VERTEX_COLOR, true)
	material.set_flag(SpatialMaterial.FLAG_SRGB_VERTEX_COLOR, true)
	material.set_flag(SpatialMaterial.FLAG_DISABLE_DEPTH_TEST, true)
	material.set_albedo(color)

	add_material(name, material)


func set_selected(path) -> void:
	if _selected and is_instance_valid(_selected):
		if _selected.is_connected("curve_changed", self, "_on_curve_changed"):
			_selected.disconnect("curve_changed", self, "_on_curve_changed")

	_selected = path

	if not path:
		return

	if not path is _namespace.ScatterPath:
		path = null
		return

	if not path.is_connected("curve_changed", self, "_on_curve_changed"):
		path.connect("curve_changed", self, "_on_curve_changed")

	_previous_state.point_count = _selected.curve.get_point_count()
	_previous_state.position = Vector3.ZERO
	if _previous_state.point_count > 0:
		_previous_state.position = _selected.curve.get_point_position(_previous_state.point_count - 1)


func set_editor_camera(camera: Camera) -> void:
	_camera = camera


func set_editor_plugin(val: EditorPlugin) -> void:
	editor_plugin = val
	_undo = editor_plugin.get_undo_redo()
	_previous_state.version = _undo.get_version()


func _draw_handles(gizmo):
	var path = gizmo.get_spatial_node()
	if not path:
		return

	var curve = path.curve
	if not curve:
		return

	var handles = PoolVector3Array()
	var square_handles = PoolVector3Array()
	var lines = PoolVector3Array()
	var count = curve.get_point_count()
	if count == 0:
		return

	for i in count:
		var point_pos = curve.get_point_position(i)
		var point_in = curve.get_point_in(i) + point_pos
		var point_out = curve.get_point_out(i) + point_pos

		lines.push_back(point_pos)
		lines.push_back(point_in)
		lines.push_back(point_pos)
		lines.push_back(point_out)

		square_handles.push_back(point_in)
		square_handles.push_back(point_out)
		handles.push_back(point_pos)

	gizmo.add_handles(handles, get_material("handles", gizmo))
	gizmo.add_handles(square_handles, get_material("square_handle", gizmo))
	gizmo.add_lines(lines, get_material("handle_lines", gizmo))


func _draw_path(gizmo):
	var path = gizmo.get_spatial_node()
	var polygon = PoolVector3Array()

	for i in path.baked_points.size() - 1:
		polygon.append(path.baked_points[i])
		polygon.append(path.baked_points[i + 1])

	gizmo.add_lines(polygon, get_material("path", gizmo))
	gizmo.add_collision_segments(polygon)


func _draw_grid(gizmo):
	if options.hide_grid():
		return

	var path = gizmo.get_spatial_node()
	var grid = PoolVector3Array()
	var size = path.size
	var center = path.center
	center.y = 0.0
	size.y = 0.0

	var resolution = 10.0 / options.get_grid_density() # Define how large each square is
	var steps_x = int(size.x / resolution) + 1
	var steps_y = int(size.z / resolution) + 1
	var offset = -size / 2 + center

	for i in steps_x:
		grid.append(Vector3(i * resolution, 0.0, 0.0) + offset)
		grid.append(Vector3(i * resolution, 0.0, size.z) + offset)

	for j in steps_y:
		grid.append(Vector3(0.0, 0.0, j * resolution) + offset)
		grid.append(Vector3(size.x, 0.0, j * resolution) + offset)


	grid.append(Vector3(0.0, 0.0, size.z) + offset)
	grid.append(Vector3(size.x, 0.0, size.z) + offset)
	grid.append(Vector3(size.x, 0.0, 0.0) + offset)
	grid.append(Vector3(size.x, 0.0, size.z) + offset)

	gizmo.add_lines(grid, get_material("grid", gizmo))


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _intersect_with_colliders(path, camera, screen_point):
	var from = camera.project_ray_origin(screen_point)
	var dir = camera.project_ray_normal(screen_point)
	var space_state = path.get_world().direct_space_state
	var result = space_state.intersect_ray(from, from + dir * 4096)
	if result:
		return result.position
	return null


func _intersect_with_plane(path, camera, screen_point):
	var from = camera.project_ray_origin(screen_point)
	var dir = camera.project_ray_normal(screen_point)
	var plane = _get_path_plane(path)
	return plane.intersects_ray(from, dir)


func _intersect_screen_space(path, camera, screen_point):
	var from = camera.project_ray_origin(screen_point)
	var dir = camera.project_ray_normal(screen_point)
	var gt = path.get_global_transform()
	var point: Vector3 = gt.xform(_old_position)
	var camera_basis: Basis = camera.get_transform().basis
	var plane := Plane(point, point + camera_basis.x, point + camera_basis.y)
	return plane.intersects_ray(from, dir)


func _get_path_plane(path) -> Plane:
	var t = path.get_global_transform()
	var a = t.basis.x
	var b = t.basis.z
	var c = a + b
	var o = t.origin
	return Plane(a + o, b + o, c + o)


func _get_point_data(curve: Curve3D, index: int) -> Dictionary:
	var pos: Vector3 = curve.get_point_position(index)
	var pos_in: Vector3 = curve.get_point_in(index)
	var pos_out: Vector3 = curve.get_point_out(index)
	var tilt: float = curve.get_point_tilt(index)

	return {
		"index": index,
		"pos": pos,
		"in": pos_in,
		"out": pos_out,
		"tilt": tilt
	}


func _set_point(path, data: Dictionary) -> void:
	var index = data.index
	path.curve.set_point_position(index, data.pos)
	path.curve.set_point_in(index, data.in)
	path.curve.set_point_out(index, data.out)
	path.curve.set_point_tilt(index, data.tilt)


func _set_options(val) -> void:
	options = val
	if not options:
		return

	options.connect("option_changed", self, "_on_option_changed")
	options.connect("color_changed", self, "_on_color_changed")
	create_custom_material("grid", options.get_grid_color())
	create_custom_material("path", options.get_path_color())


func _on_option_changed() -> void:
	force_redraw()


# Force the newly added points on the plane if the option is enabled
# Could have been avoided if Scatter didn't inherited from Path
func _on_curve_changed() -> void:
	if _is_forcing_projection:
		return

	var idx: int = -1

	var current_count: int = _selected.curve.get_point_count()
	var current_position: Vector3 = Vector3.ZERO
	if current_count > 0:
		idx = current_count - 1
		current_position = _selected.curve.get_point_position(idx)
	var current_version = _undo.get_version()

	var previous_count: int = _previous_state.point_count
	var previous_pos: Vector3 = _previous_state.position

	_previous_state.point_count = current_count
	_previous_state.position = current_position
	_previous_state.version = current_version

	# There are no points in the curve, so nothing to do further.
	if idx < 0:
		return

	# Ensure we're constrained by the plane
	if not options:
		return

	if not options.lock_to_plane():
		return

	if not options.force_plane_projection():
		return

	# Ensure a new point was added
	if previous_count >= current_count:
		return

	# Ensure the newly added point is the last one, not one in the middle of
	# an existing segment
	if previous_pos == current_position:
		return

	# TODO: Ensure the new point is NOT the result of a redo command

	var new_position := current_position

	if _camera:
		var point = _camera.unproject_position(_selected.to_global(current_position))
		var projected = _intersect_with_plane(_selected, _camera, point)
		new_position = _selected.to_local(projected)
	else:
		new_position.y = 0.0

	_is_forcing_projection = true
	_selected.curve.set_point_position(idx, new_position)
	_is_forcing_projection = false


func _on_color_changed() -> void:
	create_custom_material("grid", options.get_grid_color())
	create_custom_material("path", options.get_path_color())
	force_redraw()
