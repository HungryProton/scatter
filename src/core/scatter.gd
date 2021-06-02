tool
extends "scatter_path.gd"


var Scatter = preload("namespace.gd").new()

export var global_seed := 0 setget _set_global_seed
export var use_instancing := true setget _set_instancing
export var disable_updates_in_game := true

var modifier_stack setget _set_modifier_stack
var undo_redo setget _set_undo_redo

var _transforms
var _items := []
var _total_proportion: int
var _was_duplicated := false


func _ready() -> void:
	if not modifier_stack:
		modifier_stack = Scatter.ModifierStack.new()
		modifier_stack.just_created = true

	self.connect("curve_updated", self, "update")
	_discover_items()


func add_child(node, legible_name := false) -> void:
	.add_child(node, legible_name)
	_discover_items()


func remove_child(node) -> void:
	.remove_child(node)
	_discover_items()


func _get_configuration_warning() -> String:
	if _items.empty():
		return "Scatter requires at least one ScatterItem node as a child to work."
	return ""


func _get_property_list() -> Array:
	var list := []

	# Used to display the modifier stack in an inspector plugin.
	list.push_back({
		name = "modifier_stack",
		type = TYPE_OBJECT,
		hint_string =  "ScatterModifierStack",
	})
	return list


func _get(property):
	if property == "modifier_stack":
		return modifier_stack
	return null


func _set(property, value):
	if property == "modifier_stack":
		# TODO: This duplicate is there because I couldn't find a way to detect
		# when a node is duplicated from the editor and I don't want multiple
		# scatter nodes to share the same stack.
		modifier_stack = value.duplicate(7)
		call_deferred("clear")
		return true

	# For some reason, set_modifier_stack is not always called when duplicating
	# a node, but other parameters like transforms are so we check that as well
	if property == "transform":
		if modifier_stack:
			modifier_stack = modifier_stack.duplicate(7)
		else:
			modifier_stack = Scatter.ModifierStack.new()
			modifier_stack.just_created = true
		# Duplicate the curve item too. If someone want to share data, it has
		# to be explicitely done by the user

		call_deferred("_make_curve_unique")
		call_deferred("clear")

	return false


func clear() -> void:
	_discover_items()
	_delete_duplicates()
	_delete_multimeshes()


func update() -> void:
	if disable_updates_in_game and not Engine.is_editor_hint():
		return

	_discover_items()
	if not _items.empty():
		_transforms = Scatter.Transforms.new()
		_transforms.set_path(self)

		if use_instancing:
			modifier_stack.update(_transforms, global_seed)
			_create_multimesh()
		else:
			_set_colliders_state(self, false)
			modifier_stack.update(_transforms, global_seed)
			_set_colliders_state(self, true)
			_create_duplicates()

	_notify_parent()


func _notify_parent() -> void:
	var parent = get_parent()
	if not parent:
		return

	if parent is Scatter.Scatter or parent is Scatter.UpdateGroup:
		parent.update()


# Same thing as update except we force all the physic objects in the entire
# scene to refresh their colliders. We have to do this because of reasons
# explained here: https://github.com/godotengine/godot/issues/43744
func full_update() -> void:
	_reset_all_colliders(get_tree().root)
	_delete_duplicates()
	_delete_multimeshes()
	yield(get_tree(), "idle_frame")
	update()


# Loop through children to find all the ScatterItem nodes
func _discover_items() -> void:
	_items.clear()
	_total_proportion = 0

	for c in get_children():
		if c is Scatter.ScatterItem:
			_items.append(c)
			_total_proportion += c.proportion

	if is_inside_tree():
		get_tree().emit_signal("node_configuration_warning_changed", self)


func _create_duplicates() -> void:
	var offset := 0
	var transforms_count: int = _transforms.list.size()

	for item in _items:
		var count = int(round(float(item.proportion) / _total_proportion * transforms_count))
		var root = _get_or_create_instances_root(item)
		var instances = root.get_children()
		var child_count = instances.size()

		for i in count:
			if (offset + i) >= transforms_count:
				return
			var instance
			if i < child_count:
				# Grab an instance from the pool if there's one available
				instance = instances[i]
			else:
				# If not, create one
				instance = _create_instance(item, root)

			instance.transform = _process_transform(item, _transforms.list[offset + i])

		# Delete the unused instances left in the pool if any
		if count < child_count:
			for i in (child_count - count):
				instances[count + i].queue_free()

		offset += count


func _get_or_create_instances_root(item):
	var root: Spatial
	if item.has_node("Duplicates"):
		root = item.get_node("Duplicates")
	else:
		root = Spatial.new()
		root.set_name("Duplicates")
		item.add_child(root)
		root.set_owner(get_tree().get_edited_scene_root())
	root.translation = Vector3.ZERO
	return root


func _create_instance(item, root):
	var instance = item.get_item_node()
	root.add_child(instance)
	if item.is_local():
		_set_owner_recursive(instance, get_tree().get_edited_scene_root())
	else:
		instance.set_owner(get_tree().get_edited_scene_root())

	return instance


func _delete_duplicates():
	for item in _items:
		if item.has_node("Duplicates"):
			item.get_node("Duplicates").queue_free()


func _create_multimesh() -> void:
	var offset := 0
	var transforms_count: int = _transforms.list.size()

	for item in _items:
		item.translation = Vector3.ZERO
		item.rotation = Vector3.ZERO
		item.scale = Vector3.ONE
		var count = int(round(float(item.proportion) / _total_proportion * transforms_count))
		var mmi = _setup_multi_mesh(item, count)
		if not mmi:
			return

		for i in count:
			if (offset + i) >= transforms_count:
				return

			mmi.multimesh.set_instance_transform(i, _process_transform(item, _transforms.list[offset + i]))
			mmi.multimesh.visible_instance_count = i + 1

		offset += count


func _setup_multi_mesh(item, count):
	var instance: MultiMeshInstance
	if item.has_node("MultiMeshInstance"):
		instance = item.get_node("MultiMeshInstance")
	else:
		instance = MultiMeshInstance.new()
		instance.set_name("MultiMeshInstance")
		item.add_child(instance)
		instance.set_owner(get_tree().get_edited_scene_root())

	if not instance.multimesh:
		instance.multimesh = MultiMesh.new()

	instance.translation = Vector3.ZERO

	var mesh_instance: MeshInstance = item.get_mesh_instance()
	if not mesh_instance:
		_delete_multimeshes()
		return

	for i in mesh_instance.get_surface_material_count():
		var mat = mesh_instance.get_surface_material(i)
		if not mat:
			continue
		mesh_instance.mesh.surface_set_material(i, mat)

	instance.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	instance.multimesh.mesh = mesh_instance.mesh
	instance.multimesh.transform_format = 1
	instance.multimesh.instance_count = count
	instance.material_override = mesh_instance.material_override

	return instance


func _delete_multimeshes() -> void:
	if _items.empty():
		_discover_items()

	for item in _items:
		if item.has_node("MultiMeshInstance"):
			item.get_node("MultiMeshInstance").queue_free()


func _process_transform(item, t: Transform) -> Transform:
	var origin = t.origin
	t.origin = Vector3.ZERO

	t = t.scaled(Vector3.ONE * item.scale_modifier)

	if not item.ignore_initial_scale:
		t = t.scaled(item.initial_scale)

	if not item.ignore_initial_rotation:
		t = t.rotated(t.basis.x.normalized(), item.initial_rotation.x)
		t = t.rotated(t.basis.y.normalized(), item.initial_rotation.y)
		t = t.rotated(t.basis.z.normalized(), item.initial_rotation.z)

	t.origin = origin

	if not item.ignore_initial_position:
		t.origin += item.initial_position

	return t


func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.set_owner(owner)
	for c in node.get_children():
		_set_owner_recursive(c, owner)


func _set_global_seed(val: int) -> void:
	global_seed = val
	update()


func _set_instancing(val: bool) -> void:
	use_instancing = val
	if use_instancing:
		_delete_duplicates()
	else:
		_delete_multimeshes()
	update()


func _set_undo_redo(val) -> void:
	undo_redo = val
	modifier_stack.undo_redo = val


func _set_modifier_stack(val) -> void:
	modifier_stack = Scatter.ModifierStack.new()
	modifier_stack.stack = val.duplicate_stack()

	if not modifier_stack.is_connected("stack_changed", self, "update"):
		modifier_stack.connect("stack_changed", self, "update")


func _make_curve_unique() -> void:
	curve = curve.duplicate(true)
	_update_from_curve()


func _reset_all_colliders(node) -> void:
	if node is CollisionShape and not node.disabled:
		node.disabled = true
		node.disabled = false

	for c in node.get_children():
		_reset_all_colliders(c)


func _set_colliders_state(node, enabled: bool) -> void:
	if node is CollisionShape:
		node.disabled = not enabled

	for c in node.get_children():
		_set_colliders_state(c, enabled)
