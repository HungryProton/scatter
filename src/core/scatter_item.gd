tool
extends Spatial


const Util = preload("../common/util.gd")

export var proportion := 100 setget _set_proportion
export var local_item_path: NodePath setget _set_local_path
export(String, FILE) var item_path setget _set_path
export var scale_modifier := 1.0 setget _set_scale_modifier
export var ignore_initial_position := true setget _set_ignore_pos
export var ignore_initial_rotation := true setget _set_ignore_rot
export var ignore_initial_scale := true setget _set_ignore_scale

var use_instancing := true setget _set_use_instancing
var merge_target_meshes := false setget _set_merge_target_meshes
var cast_shadow := 1 setget _set_cast_shadow

var initial_position: Vector3
var initial_rotation: Vector3
var initial_scale: Vector3

var materials := []

var _parent


func _ready():
	_parent = get_parent()
	_restore_multimesh_materials()
	use_instancing = _parent.use_instancing


func _get_configuration_warning() -> String:
	if local_item_path.is_empty() and item_path.empty():
		return """ No source Node found! You need either ONE of the following:

			- If the Node you want to scatter is in this scene, fill the 'Local Item Path' variable.
			- If your Node is in another scene, fill the 'Item Path' variable.
		"""
	return ""


func _get_property_list() -> Array:
	var list = []

	list.push_back({
		"name": "materials",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE
	})

	var merge_target_meshes_property = {
		"name": "merge_target_meshes",
		"type": TYPE_BOOL,
	}
	var cast_shadow_property = {
		"name": "cast_shadow",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Off,On,Double-Sided,Shadows Only"
	}

	# Only display the options if instancing is used but store the
	# previous values if it's not
	if not use_instancing:
		merge_target_meshes_property["usage"] = PROPERTY_USAGE_STORAGE
		cast_shadow_property["usage"] = PROPERTY_USAGE_STORAGE

	list.push_back(merge_target_meshes_property)
	list.push_back(cast_shadow_property)

	return list


func _set(property, _value):
	# Hack to detect if the node was just duplicated from the editor
	if property == "transform":
		call_deferred("delete_multimesh")
	return false


func update():
	_parent = get_parent()
	if _parent:
		_parent.update()


func get_mesh_instance_copy() -> MeshInstance:
	var root = null
	var local_root = false

	if local_item_path:
		root = get_node_or_null(local_item_path)
		local_root = true

	if item_path:
		var scene = load(item_path)
		if scene:
			root = scene.instance()

	if root:
		var mesh = _get_mesh_from_scene(root)
		if not local_root:
			root.queue_free()
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


func get_multimesh_instance() -> MultiMeshInstance:
	for c in get_children():
		if c is MultiMeshInstance:
			return c
	return null


func delete_multimesh() -> void:
	for c in get_children():
		if c is MultiMeshInstance:
			c.queue_free()


func delete_duplicates() -> void:
	for c in get_children():
		if c.name.begins_with("Duplicates"):
			c.queue_free()


func update_shadows() -> void:
	var mmi: MultiMeshInstance = get_multimesh_instance()
	if not mmi:
		return

	mmi.cast_shadow = cast_shadow


func _get_mesh_from_scene(node):
	if merge_target_meshes:
		return _get_merged_mesh_from(node)

	return _get_first_mesh_from_scene(node)


# Finds the first MeshInstance in the given hierarchy and returns it.
func _get_first_mesh_from_scene(node):
	if node is MeshInstance:
		return node.duplicate()

	for c in node.get_children():
		var res = _get_first_mesh_from_scene(c)
		if res:
			return res

	return null


# Find all the meshes in the tree and create a new mesh with multiple surfaces
# from all of them
func _get_merged_mesh_from(node):
	var instances = _get_all_mesh_instances_from(node)
	if not instances or instances.empty():
		return null

	var mesh_instance := MeshInstance.new()
	mesh_instance.mesh = Util.create_mesh_from(instances)

	return mesh_instance


func _get_all_mesh_instances_from(node) -> Array:
	var res = []
	if node is MeshInstance:
		res.push_back(node)

	for c in node.get_children():
		res += _get_all_mesh_instances_from(c)

	return res


func _save_initial_data(mesh: MeshInstance) -> void:
	if not mesh:
		return

	initial_position = mesh.translation
	initial_rotation = mesh.rotation
	initial_scale = mesh.scale

	# Save the materials applied to the mesh instance, not on the mesh itself
	# Needed for obj meshes with multiple surfaces
	materials = []
	for i in mesh.get_surface_material_count():
		materials.append(mesh.get_surface_material(i))


func _restore_multimesh_materials() -> void:
	var mmi := get_multimesh_instance()
	if not mmi:
		return

	var mesh: Mesh = mmi.multimesh.mesh
	if not mesh:
		return

	var surface_count = mesh.get_surface_count()

	if not mesh or surface_count > materials.size():
		return

	for i in surface_count:
		var material = materials[i]
		if material:
			mesh.surface_set_material(i, material)


func _set_proportion(val: int) -> void:
	proportion = val
	update()


func _set_path(val: String) -> void:
	item_path = val
	update()


func _set_scale_modifier(val: float) -> void:
	scale_modifier = val
	update()


func _set_local_path(val: NodePath) -> void:
	local_item_path = val
	update()


func _set_ignore_pos(val: bool) -> void:
	ignore_initial_position = val
	update()


func _set_ignore_rot(val: bool) -> void:
	ignore_initial_rotation = val
	update()


func _set_ignore_scale(val: bool) -> void:
	ignore_initial_scale = val
	update()


func _set_use_instancing(val: bool) -> void:
	use_instancing = val
	property_list_changed_notify()


func _set_cast_shadow(val: int) -> void:
	cast_shadow = val
	update_shadows()


func _set_merge_target_meshes(val: bool) -> void:
	merge_target_meshes = val
	update()
