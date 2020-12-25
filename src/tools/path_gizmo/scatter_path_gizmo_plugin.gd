extends EditorSpatialGizmoPlugin


var editor_plugin: EditorPlugin
var options setget _set_options

var _previous_size
var _namespace = load(_get_root_folder() + "/src/core/namespace.gd").new()
var _axis_mesh: ArrayMesh
var _cached_gizmo
var _old_position


func _init():
	create_custom_material("path", Color(1, 0, 0))
	create_custom_material("grid", Color(1, 0.7, 0))
	create_custom_material("handle_lines", Color(0.1, 0.1, 0.1))
	create_handle_material("handles")
	
	var in_out_icon = ImageTexture.new()
	in_out_icon.load(_get_root_folder() + "/icons/square_handle.svg")
	create_custom_handle_material("square_handle", in_out_icon)

	var axis_icon = ImageTexture.new()
	axis_icon.load(_get_root_folder() + "/icons/axis_handle.svg")
	create_custom_handle_material("axis_handle", axis_icon)


func get_name() -> String:
	return "ScatterPath"


func has_gizmo(node):
	return node is _namespace.ScatterPath


func get_handle_name(gizmo: EditorSpatialGizmo, index: int) -> String:
	return "Handle " + String(index)


func get_handle_value(gizmo: EditorSpatialGizmo, index: int):
	var path = gizmo.get_spatial_node()
	var curve: Curve3D = path.get_curve()
	if not curve:
		return null
	
	var count = curve.get_point_count()
	if index < count:
		_old_position = curve.get_point_position(index);
		return _old_position

	var i = (index - count)
	var p_index = int(i / 2)
	var value: Vector3
	
	if i % 2 == 0:
		value = curve.get_point_in(p_index)
	else:
		value = curve.get_point_out(p_index)

	_old_position = value + curve.get_point_position(p_index)
	return value


# Automatically called when a handle is moved around.
func set_handle(gizmo: EditorSpatialGizmo, index: int, camera: Camera, point: Vector2) -> void:
	var path = gizmo.get_spatial_node()
	var local_pos
	
	if options.snap_to_colliders():
		local_pos = _intersect_with_colliders(path, camera, point)
	
	elif options.lock_to_plane():
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


# Handle Undo / Redo after a handle was moved.
func commit_handle(gizmo: EditorSpatialGizmo, index: int, restore, cancel: bool = false) -> void:
	var path = gizmo.get_spatial_node()
	var ur = editor_plugin.get_undo_redo()
	# TODO


func redraw(gizmo: EditorSpatialGizmo):
	_cached_gizmo = gizmo
	gizmo.clear()
	
	_draw_handles(gizmo)
	_draw_path(gizmo)
	if options.lock_to_plane():
		_draw_grid(gizmo)


func create_custom_handle_material(name, icon: Texture, color := Color.white):
	var handle_material = SpatialMaterial.new()
	handle_material.render_priority = 1
	
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
	material.render_priority = 1
	
	material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	material.set_flag(SpatialMaterial.FLAG_ALBEDO_FROM_VERTEX_COLOR, true)
	material.set_flag(SpatialMaterial.FLAG_SRGB_VERTEX_COLOR, true)
	material.set_flag(SpatialMaterial.FLAG_DISABLE_DEPTH_TEST, true)
	material.set_albedo(color)
	
	add_material(name, material)


func _draw_handles(gizmo):
	var curve = gizmo.get_spatial_node().curve
	var handles = PoolVector3Array()
	var square_handles = PoolVector3Array()
	var axis_handles = PoolVector3Array()
	var lines = PoolVector3Array()
	var count = curve.get_point_count()
	if count == 0:
		return
	
	for i in range(count):
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
		
	gizmo.add_handles(handles, get_material("handles"))
	gizmo.add_handles(square_handles, get_material("square_handle"))
	gizmo.add_lines(lines, get_material("handle_lines"))


func _draw_path(gizmo):
	var path = gizmo.get_spatial_node()
	var polygon = PoolVector3Array()
	
	for i in path.baked_points.size() - 1:
		polygon.append(path.baked_points[i])
		polygon.append(path.baked_points[i + 1])
	
	gizmo.add_lines(polygon, get_material("path", gizmo))
	gizmo.add_collision_segments(polygon)


func _draw_grid(gizmo):
	var path = gizmo.get_spatial_node()
	var grid = PoolVector3Array()
	var size = path.size
	var center = path.center
	var resolution = 2.0 # Define how large each square is
	var steps_x = int(size.x / resolution) + 1
	var steps_y = int(size.z / resolution) + 1
	var half_size = size/2
	
	for i in range(steps_x):
		grid.append(Vector3(i*resolution, 0.0, 0.0) - half_size + center)
		grid.append(Vector3(i*resolution, 0.0, size.z) - half_size + center)
	for j in range(steps_y):
		grid.append(Vector3(0.0, 0.0, j*resolution) - half_size + center)
		grid.append(Vector3(size.x, 0.0, j*resolution) - half_size + center)
	
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


func _set_options(val) -> void:
	options = val
	options.connect("option_changed", self, "_on_option_changed")


func _on_option_changed() -> void:
	redraw(_cached_gizmo)
