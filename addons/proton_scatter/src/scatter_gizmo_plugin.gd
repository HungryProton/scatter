@tool
extends EditorNode3DGizmoPlugin


# Gizmo plugin for the ProtonScatter nodes.
#
# Displays a loading animation when the node is rebuilding its output
# Also displays the domain edges if one of its modifiers is using this data.


const ProtonScatter := preload("./scatter.gd")
const LoadingAnimation := preload("../icons/loading/m_loading.tres")

var _loading_mesh: Mesh
var _editor_plugin: EditorPlugin


func _init():
	# TODO: Replace hardcoded colors by a setting fetch
	create_custom_material("line", Color(0.2, 0.4, 0.8))
	add_material("loading", LoadingAnimation)

	_loading_mesh = QuadMesh.new()
	_loading_mesh.set_size(Vector2.ONE * 0.15)


func _get_gizmo_name() -> String:
	return "ProtonScatter"


func _has_gizmo(node) -> bool:
	return node is ProtonScatter


func _redraw(gizmo: EditorNode3DGizmo):
	gizmo.clear()
	var node = gizmo.get_node_3d()

	if not node.modifier_stack:
		return

	if node.is_thread_running():
		gizmo.add_mesh(_loading_mesh, get_material("loading"))

	if node.modifier_stack.is_using_edge_data() and _is_selected(node):
		var curves: Array[Curve3D] = node.domain.get_edges()

		for curve in curves:
			var lines := PackedVector3Array()
			var points: PackedVector3Array = curve.tessellate(4, 8)
			var lines_count := points.size() - 1

			for i in lines_count:
				lines.append(points[i])
				lines.append(points[i + 1])

			gizmo.add_lines(lines, get_material("line"))


func set_editor_plugin(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin


# WORKAROUND
# Creates a standard material displayed on top of everything.
# Only exists because 'create_material() on_top' parameter doesn't seem to work.
func create_custom_material(name, color := Color.WHITE):
	var material := StandardMaterial3D.new()
	material.set_blend_mode(StandardMaterial3D.BLEND_MODE_ADD)
	material.set_shading_mode(StandardMaterial3D.SHADING_MODE_UNSHADED)
	material.set_flag(StandardMaterial3D.FLAG_DISABLE_DEPTH_TEST, true)
	material.set_albedo(color)
	material.render_priority = 100

	add_material(name, material)


func _is_selected(node: Node) -> bool:
	if ProjectSettings.get_setting(_editor_plugin.GIZMO_SETTING):
		return true

	return node in _editor_plugin.get_custom_selection()
