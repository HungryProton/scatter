@tool
extends EditorNode3DGizmoPlugin


#

const Scatter := preload("./scatter.gd")

var _panel
var _loading_mesh: Mesh


func _init():
	# TODO: Replace hardcoded colors by a setting fetch
	create_custom_material("line", Color(1, 0.4, 0))
	add_material("loading", preload("../misc/m_loading.tres"))

	_loading_mesh = QuadMesh.new()
	_loading_mesh.set_size(Vector2.ONE * 0.2)


func _get_gizmo_name() -> String:
	return "ProtonScatter"


func _has_gizmo(node) -> bool:
	return node is Scatter


func _redraw(gizmo: EditorNode3DGizmo):
	gizmo.clear()
	var node = gizmo.get_node_3d()
	if node.is_thread_running():
		gizmo.add_mesh(_loading_mesh, get_material("loading"))


func set_path_gizmo_panel(panel: Control) -> void:
	_panel = panel


func set_editor_plugin(plugin: EditorPlugin) -> void:
	pass


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
