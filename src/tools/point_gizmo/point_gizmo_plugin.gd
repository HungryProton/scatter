@tool
extends EditorNode3DGizmoPlugin


var Scatter = preload("../../core/namespace.gd")

var _selected
var _gizmo


func _init():
	create_material("lines", Color(1, 0.7, 0))


func get_name() -> String:
	return "ScatterPoint"


func has_gizmo(node):
	return node is Scatter.Point


func redraw(gizmo: EditorNode3DGizmo):
	_gizmo = gizmo
	if not gizmo:
		return

	gizmo.clear()
	var point = gizmo.get_spatial_node()
	_update_current(point)

	var lines = PackedVector3Array()
	var steps = 32
	var step_angle = 2 * PI / steps
	var radius = point.radius

	for i in steps:
		lines.append(Vector3(cos(i * step_angle), sin(i * step_angle), 0.0) * radius)
		lines.append(Vector3(cos((i + 1) * step_angle), sin((i + 1) * step_angle), 0.0) * radius)

	for i in steps:
		lines.append(Vector3(cos(i * step_angle), 0.0, sin(i * step_angle)) * radius)
		lines.append(Vector3(cos((i + 1) * step_angle), 0.0, sin((i + 1) * step_angle)) * radius)

	for i in steps:
		lines.append(Vector3(0.0, cos(i * step_angle), sin(i * step_angle)) * radius)
		lines.append(Vector3(0.0, cos((i + 1) * step_angle), sin((i + 1) * step_angle)) * radius)

	gizmo.add_lines(lines, get_material("lines", gizmo))
	gizmo.add_collision_segments(lines)


func _update_current(point) -> void:
	if point == _selected:
		return

	if _selected and is_instance_valid(_selected):
		if _selected.is_connected("parameter_changed", self, "_on_parameter_changed"):
			_selected.disconnect("parameter_changed", self, "_on_parameter_changed")

	_selected = point
	_selected.connect("parameter_changed", self, "_on_parameter_changed")


func _on_parameter_changed() -> void:
	redraw(_gizmo)
