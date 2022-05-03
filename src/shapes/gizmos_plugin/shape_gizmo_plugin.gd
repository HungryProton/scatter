@tool
extends EditorNode3DGizmoPlugin


const ScatterShape = preload("../../scatter_shape.gd")
const PointShape = preload("../point_shape.gd")
const PathShape = preload("../path_shape.gd")


func _init():
	# TODO: Replace hardcoded color by a setting fetch
	create_material("line", Color(1, 0.7, 0))


func _get_gizmo_name() -> String:
	return "ScatterShape"


func _has_gizmo(node):
	return node is ScatterShape


func _redraw(gizmo: EditorNode3DGizmo):
	gizmo.clear()
	var shape = gizmo.get_spatial_node().shape

	match shape.get_script():
		PointShape:
			_draw_point_gizmo(gizmo, shape)
		PathShape:
			_draw_path_gizmo(gizmo, shape)


func _draw_point_gizmo(gizmo: EditorNode3DGizmo, shape: PointShape):
	var lines = PackedVector3Array()
	var steps = 32
	var step_angle = 2 * PI / steps
	var radius = shape.radius

	for i in steps:
		lines.append(Vector3(cos(i * step_angle), sin(i * step_angle), 0.0) * radius)
		lines.append(Vector3(cos((i + 1) * step_angle), sin((i + 1) * step_angle), 0.0) * radius)

	for i in steps:
		lines.append(Vector3(cos(i * step_angle), 0.0, sin(i * step_angle)) * radius)
		lines.append(Vector3(cos((i + 1) * step_angle), 0.0, sin((i + 1) * step_angle)) * radius)

	for i in steps:
		lines.append(Vector3(0.0, cos(i * step_angle), sin(i * step_angle)) * radius)
		lines.append(Vector3(0.0, cos((i + 1) * step_angle), sin((i + 1) * step_angle)) * radius)

	gizmo.add_lines(lines, get_material("line", gizmo))
	gizmo.add_collision_segments(lines)


func _draw_path_gizmo(gizmo: EditorNode3DGizmo, shape: PathShape):
	pass
