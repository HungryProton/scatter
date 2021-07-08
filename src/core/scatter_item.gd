tool
extends Spatial


export(int) var proportion : int = 100 setget _set_proportion
export(NodePath) var local_item_path setget _set_local_path
export(String, FILE) var item_path : String setget _set_path
export(float) var scale_modifier : float = 1.0 setget _set_scale_modifier
export(bool) var ignore_initial_position := true setget _set_ignore_pos
export(bool) var ignore_initial_rotation := true setget _set_ignore_rot
export(bool) var ignore_initial_scale := true setget _set_ignore_scale

var initial_position: Vector3
var initial_rotation: Vector3
var initial_scale: Vector3

var materials := []

var _parent


func _ready():
	_parent = get_parent()
	_restore_multimesh_materials()


func _get_configuration_warning() -> String:
	if local_item_path.is_empty() and item_path.empty():
		return """ No source Node found! You need either ONE of the following:

			- If the Node you want to scatter is in this scene, fill the 'Local Item Path' variable.
			- If your Node is in another scene, fill the 'Item Path' variable.
		"""
	return ""


func _get_property_list() -> Array:
	return [{
		"name": "materials",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE
	}]


func _set(property, _value):
	# Hack to detect if the node was just duplicated from the editor
	if property == "transform":
		call_deferred("_delete_multimesh")
	return false


func update():
	_parent = get_parent()
	if _parent:
		_parent.update()


func get_mesh_instance() -> MeshInstance:
	# Check the supplied local path.
	if local_item_path:
		if has_node(local_item_path):
			var mesh = _get_mesh_from_scene(get_node(local_item_path))
			if mesh:
				_save_initial_data(mesh)
				return mesh

	# Check the remote scene.
	if item_path:
		var node = load(item_path)
		if node:
			var mesh = _get_mesh_from_scene(node.instance())
			if mesh:
				_save_initial_data(mesh)
				return mesh

	# Nothing found, print the relevant warning in the console.
	if local_item_path:
		printerr("Warning: ", name, "/local_item_path - ", local_item_path, " is not a valid MeshInstance")
	if item_path:
		printerr("Warning: ", item_path, " is not a valid scene file")

	return null


func get_item_node():
	# Check the supplied local path.
	if local_item_path:
		if has_node(local_item_path):
			var node = get_node(local_item_path).duplicate()
			_save_initial_data(node)
			var parent = node.get_parent()
			if parent:
				parent.remove_child(node)
			return node

	# Check the remote scene.
	if item_path:
		var scene = load(item_path)
		if scene:
			var node = scene.instance()
			_save_initial_data(node)
			return node

	# Nothing found, print the relevant warning in the console.
	if local_item_path:
		printerr("Warning: ", name, "/local_item_path - ", local_item_path, " is not a valid node path")
	if item_path:
		printerr("Warning: ", item_path, " is not a valid scene file")

	return null


func is_local() -> bool:
	return not local_item_path.is_empty()


func update_warning() -> void:
	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)


func _delete_multimesh() -> void:
	if has_node("MultiMeshInstance"):
		get_node("MultiMeshInstance").queue_free()


func _get_mesh_from_scene(node):
	if node is MeshInstance:
		return node

	for c in node.get_children():
		var res = _get_mesh_from_scene(c)
		if res:
			return res#.duplicate()

	return null


func _save_initial_data(mesh: MeshInstance) -> void:
	initial_position = mesh.translation
	initial_rotation = mesh.rotation
	initial_scale = mesh.scale

	# Save the materials applied to the mesh instance, not on the mesh itself
	# Needed for obj meshes with multiple surfaces
	materials = []
	for i in mesh.get_surface_material_count():
		materials.append(mesh.get_surface_material(i))


func _restore_multimesh_materials():
	if not has_node("MultiMeshInstance"):
		return

	var mmi: MultiMeshInstance = get_node("MultiMeshInstance")
	var mesh: Mesh = mmi.multimesh.mesh
	var surface_count = mesh.get_surface_count()

	if not mesh or surface_count > materials.size():
		return

	for i in surface_count:
		mesh.surface_set_material(i, materials[i])


func _set_proportion(val):
	proportion = val
	update()


func _set_path(val):
	item_path = val
	update()


func _set_scale_modifier(val):
	scale_modifier = val
	update()


func _set_local_path(val):
	local_item_path = val
	update()


func _set_ignore_pos(val):
	ignore_initial_position = val
	update()


func _set_ignore_rot(val):
	ignore_initial_rotation = val
	update()


func _set_ignore_scale(val):
	ignore_initial_scale = val
	update()
