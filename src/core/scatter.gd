tool
extends "scatter_path.gd"


export var global_seed := 0 setget _set_global_seed
export var use_instancing := true setget _set_instancing
export var disable_updates_in_game := true

var modifier_stack setget _set_modifier_stack

var _namespace = preload("./namespace.gd").new()
var _transforms
var _items := []
var _total_proportion: int


func _ready() -> void:
	if not modifier_stack:
		modifier_stack = _namespace.ModifierStack.new()
		modifier_stack.just_created = true

	self.connect("curve_updated", self, "update")


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
		return true
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
		_transforms = _namespace.Transforms.new()
		_transforms.set_path(self)
		modifier_stack.update(_transforms, global_seed)
		
		if use_instancing:
			_delete_duplicates()
			_create_multimesh()
		else:
			_delete_multimeshes()
			_create_duplicates()
	
	var parent = get_parent()
	if parent and parent.has_method("update"):
		parent.update()


# Loop through children to find all the ScatterItem nodes
func _discover_items() -> void:
	_items.clear()
	_total_proportion = 0

	for c in get_children():
		if c is _namespace.ScatterItem:
			_items.append(c)
			_total_proportion += c.proportion


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
			
			instance.transform = _transforms.list[offset + i]
		
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
	# Create item and add it to the scene
	var instance = load(item.item_path).instance()
	root.add_child(instance)
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
		var count = int(round(float(item.proportion) / _total_proportion * transforms_count))
		var mmi = _setup_multi_mesh(item, count)

		for i in count:
			if (offset + i) >= transforms_count:
				return
			mmi.multimesh.set_instance_transform(i, _transforms.list[offset + i])
		offset += count


func _setup_multi_mesh(item, count):
	var instance = item.get_node("MultiMeshInstance")
	if not instance:
		instance = MultiMeshInstance.new()
		instance.set_name("MultiMeshInstance")
		item.add_child(instance)
		instance.set_owner(get_tree().get_edited_scene_root())
	if not instance.multimesh:
		instance.multimesh = MultiMesh.new()
	instance.translation = Vector3.ZERO

	var mesh_instance = _get_mesh_from_scene(item.item_path)
	instance.material_override = mesh_instance.get_surface_material(0)
	instance.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	instance.multimesh.mesh = mesh_instance.mesh
	instance.multimesh.transform_format = 1
	instance.multimesh.instance_count = count

	return instance


func _get_mesh_from_scene(node_path):
	var target = load(node_path).instance()
	for c in target.get_children():
		if c is MeshInstance:
			target.queue_free()
			return c
		
		for c2 in c.get_children():
			var res = _get_mesh_from_scene(c2)
			if res:
				return res
	return null


func _delete_multimeshes() -> void:
	for item in _items:
		if item.has_node("MultiMeshInstance"):
			item.get_node("MultiMeshInstance").queue_free()


func _set_global_seed(val: int) -> void:
	global_seed = val
	update()


func _set_instancing(val: bool) -> void:
	use_instancing = val
	update()


func _set_modifier_stack(val) -> void:
	modifier_stack = val
	if not modifier_stack.is_connected("stack_changed", self, "update"):
		modifier_stack.connect("stack_changed", self, "update")
