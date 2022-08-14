tool
extends "scatter_path.gd"


var Scatter = preload("namespace.gd").new()

export var global_seed := 0 setget _set_global_seed
export var use_instancing := true setget _set_instancing
export var split_multimesh := false setget _split_multimesh
export var split_x_count : = 1
export var split_y_count : = 1
export var split_z_count : = 1
export var disable_updates_in_game := true
export var force_update_when_loaded := true
export var make_children_unselectable := true
export var preview_count := -1

var modifier_stack setget _set_modifier_stack
var undo_redo setget _set_undo_redo
var is_moving := false

var _transforms
var _items := []
var _total_proportion: int


func _ready() -> void:
	var _err = self.connect("curve_updated", self, "update")
	_ensure_stack_exists()
	_discover_items()

	if _items.empty():
		var item = Scatter.ScatterItem.new()
		add_child(item)
		item.set_owner(get_tree().get_edited_scene_root())
		item.set_name("ScatterItem")

	if force_update_when_loaded:
		yield(get_tree(), "idle_frame")
		_do_update()


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


func _set(property, _value):
	if not Engine.editor_hint:
		return false
	
	# This is to detect when the node was duplicated from the editor.
	if property == "transform":
		# Duplicate the curve item too. If someone want to share data, it has
		# to be explicitely done by the user
		call_deferred("_ensure_stack_exists")
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
	_do_update()


func _do_update() -> void:
	if not is_inside_tree():
		return

	_discover_items()
	if not _items.empty():
		if not _transforms:
			_transforms = Scatter.Transforms.new()
			_transforms.set_path(self)

		_transforms.clear()
		if is_moving:
			_transforms.max_count = preview_count
		else:
			_transforms.max_count = -1

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
		root.set_meta("_edit_group_", make_children_unselectable)
		root.set_meta("_edit_lock_", true)
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
		item.delete_duplicates()


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


# Find all children of a node recursively
func get_all_children(in_node,arr:=[]):
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr


func _split_multimesh(set) -> bool:
	var allchildren = get_all_children(self)
	if set:
		for child in allchildren:
			if child is MultiMeshInstance and not child.is_in_group("split_multimesh"):
				var is_ok = _create_split_sibling(child, self)
				if not is_ok:
					split_multimesh = false
					return false
				child.visible = false
	else:
		for child in allchildren:
			# Remove split siblings
			if child.is_in_group("split_multimesh"):
				child.queue_free()
				remove_child(child) # next loop must not find this
			elif child is MultiMeshInstance:
				child.visible = true
	split_multimesh = set
	return set


func _create_split_sibling(mmi : MultiMeshInstance, parent : Spatial) -> bool:
	if !mmi.multimesh:
		print("Cannot create split sibling, multimesh does not exist")
		return false
	if mmi.multimesh.instance_count <= 0:
		print("Cannot create split sibling, multimesh is empty")
		return false
	if split_x_count <= 0 or split_y_count <= 0 or split_z_count <= 0:
		print("Cannot create split sibling, invaild split counts")
		return false
	
	var mmi_siblings = []
	var transforms = []
	# Create mmis and multimeshes for all siblings
	for xi in range(split_x_count):
		mmi_siblings.append([])
		transforms.append([])
		for yi in range(split_y_count):
			mmi_siblings[xi].append([])
			transforms[xi].append([])
			for zi in range(split_z_count):
				transforms[xi][yi].append([])
				var sibling = MultiMeshInstance.new()
				mmi_siblings[xi][yi].append(sibling)
				
				# Set up sibling
				sibling.multimesh = MultiMesh.new()
				# copy properties to sibling
				sibling.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
				sibling.multimesh.mesh = mmi.multimesh.mesh
				sibling.multimesh.transform_format = 1
				sibling.material_override = mmi.material_override
	
	# Create the AABB from all instances
	var aabb = mmi.get_aabb()
	# avoid degenerate case later while calculating indexes
	aabb = aabb.grow(0.1)
	
	# Collect the transforms to transform arrays
	# This step is necessary to separate because mmi transforms reset when instance count changes
	for i in mmi.multimesh.instance_count:
		# both aabb and t are in mmi's local coordinates
		var t = mmi.multimesh.get_instance_transform(i)
		var p_rel = (t.origin - aabb.position) / aabb.size
		# Chunk index
		var ci = (p_rel * Vector3(split_x_count, split_y_count, split_z_count)).floor()
		# Store the transform to the appropriate array
		transforms[ci.x][ci.y][ci.z].append(t)
	
	# apply transforms, add to tree all non-empty multimesh instances
	for zi in range(split_z_count):
		for yi in range(split_y_count):
			for xi in range(split_x_count):
				# reference to current mmi based on chunk index
				var c_mmi : MultiMeshInstance = mmi_siblings[xi][yi][zi]
				if transforms[xi][yi][zi].size() == 0:
					c_mmi.queue_free()
				else:
					c_mmi.multimesh.instance_count = transforms[xi][yi][zi].size()
					for i in range(transforms[xi][yi][zi].size()):
						c_mmi.multimesh.set_instance_transform(i, transforms[xi][yi][zi][i])
					parent.add_child(c_mmi)
					c_mmi.global_transform = mmi.global_transform
					c_mmi.owner = get_tree().edited_scene_root
					c_mmi.add_to_group("split_multimesh")
					#TODO make group appear in editor
	
	return true

# Create a multimesh for item if it does not exist yet
# Copy the mesh and material data to multimesh
func _setup_multi_mesh(item, count):
	var instance: MultiMeshInstance = item.get_multimesh_instance()
	if not instance:
		instance = MultiMeshInstance.new()
		item.add_child(instance)
		instance.set_owner(get_tree().get_edited_scene_root())

	if not instance.multimesh:
		instance.multimesh = MultiMesh.new()

	instance.translation = Vector3.ZERO
	item.update_shadows()

	var mesh_instance: MeshInstance = item.get_mesh_instance_copy()
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

	instance.set_meta("_edit_group_", make_children_unselectable)
	instance.set_meta("_edit_lock_", true)

	mesh_instance.queue_free()

	return instance


func _delete_multimeshes() -> void:
	if _items.empty():
		_discover_items()

	for item in _items:
		item.delete_multimesh()


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

	for item in _items:
		item.use_instancing = val

	update()


func _set_undo_redo(val) -> void:
	undo_redo = val
	modifier_stack.undo_redo = val


func _set_modifier_stack(val) -> void:
	if not val or not is_instance_valid(val):
		return

	if modifier_stack:
		modifier_stack.queue_free()

	if val.get_parent(): # Trying to reference an existing stack, unwanted.
		modifier_stack = Scatter.ModifierStack.new()
		modifier_stack.stack = val.duplicate_stack()
	else:
		modifier_stack = val

	add_child(modifier_stack)

	if not modifier_stack.is_connected("stack_changed", self, "update"):
		modifier_stack.connect("stack_changed", self, "update")


func _make_curve_unique() -> void:
	curve = curve.duplicate(true)
	_update_from_curve()


func _ensure_stack_exists() -> void:
	if modifier_stack:
		var parent: Node = modifier_stack.get_parent()
		if not parent:
			add_child(modifier_stack)
			return

		if parent == self:
			return

		# Parent is another node, this an old reference
		modifier_stack = modifier_stack.duplicate(7)
		parent.remove_child(modifier_stack)
		add_child(modifier_stack)
	else:
		modifier_stack = Scatter.ModifierStack.new()
		modifier_stack.just_created = true
		add_child(modifier_stack)


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
