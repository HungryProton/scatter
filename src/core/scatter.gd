tool
extends Path


export var instances_count := 10 setget _set_instances_count
export var random_seed := 0 setget _set_random_seed
export var use_instancing := true setget _set_instancing


var _namespace = load(_get_root_path() + "/namespace.gd").new()
var _modifier_stack
var _transforms
var _items := []
var _total_proportion: int


func _ready() -> void:
	if not _modifier_stack:
		_modifier_stack = _namespace.ModifierStack.new()


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
		return _modifier_stack
	return null


func _set(property, value):
	if property == "modifier_stack":
		# TODO: This duplicate is there because I couldn't find a way to detect
		# when a node is duplicated from the editor and I don't want multiple
		# scatter nodes to share the same stack
		_modifier_stack = value.duplicate(7)
		return true
	return false


func update() -> void:
	_discover_items()
	if _items.empty():
		return
	
	_transforms = _namespace.Transforms.new()
	_transforms.set_count(instances_count)
	_modifier_stack.update(_transforms, random_seed)
	
	if use_instancing:
		_create_multimesh()
	else:
		_create_duplicates()


# Loop through children to find all the ScatterItem nodes
func _discover_items() -> void:
	_items.clear()
	_total_proportion = 0

	for c in get_children():
		if c is _namespace.ScatterItem:
			_items.append(c)
			_total_proportion += c.proportion


func _create_duplicates() -> void:
	pass


func _create_multimesh() -> void:
	var offset := 0
	var transforms_count: int = _transforms.list.size()
	
	for item in _items:
		var count = int(round(float(item.proportion) / _total_proportion * instances_count))
		var mmi = _setup_multi_mesh(item, count)

		for i in count:
			if (offset + i) >= transforms_count:
				break
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
	for c in target.get_children():
		for c2 in c.get_children():
			var res = _get_mesh_from_scene(c2)
			if res:
				return res


func _get_root_path() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()


func _set_instances_count(val: int) -> void:
	instances_count = val
	update()


func _set_random_seed(val: int) -> void:
	random_seed = val
	update()


func _set_instancing(val: bool) -> void:
	use_instancing = val
	update()
