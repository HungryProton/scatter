@tool
extends "gizmo_handler.gd"


const PathShape = preload("../path_shape.gd")


func redraw(plugin: EditorNode3DGizmoPlugin, gizmo: EditorNode3DGizmo):
	var shape: PathShape = gizmo.get_spatial_node().shape
	var lines = PackedVector3Array()
	var steps = 32 # TODO: Update based on sphere radius maybe ?
	var step_angle = 2 * PI / steps
	var radius = 5.0

	for i in steps:
		lines.append(Vector3(0.0, cos(i * step_angle), sin(i * step_angle)) * radius)
		lines.append(Vector3(0.0, cos((i + 1) * step_angle), sin((i + 1) * step_angle)) * radius)

	gizmo.clear()
	gizmo.add_lines(lines, plugin.get_material("line", gizmo))
	gizmo.add_collision_segments(lines)
