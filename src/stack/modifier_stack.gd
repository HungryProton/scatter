@tool
class_name ModifierStack extends Resource


signal stack_changed
signal value_changed


#const TransformList = preload("res://addons/proton_scatter/src/common/transform_list.gd")


@export var stack: Array[Resource] = []

var just_created := false


func update(scatter_node: Node3D, domain:Domain) -> TransformList:
	var transforms = TransformList.new()
	for modifier in stack:
		modifier.process_transforms(transforms, domain, scatter_node.global_seed)

	return transforms


func add(modifier) -> void:
	stack.push_back(modifier)
	stack_changed.emit()


func move(old_index: int, new_index: int) -> void:
	var modifier = stack.pop_at(old_index)
	stack.insert(new_index, modifier)
	stack_changed.emit()


func remove(modifier) -> void:
	if stack.has(modifier):
		stack.erase(modifier)
		stack_changed.emit()


func remove_at(index: int) -> void:
	if stack.size() > index:
		stack.remove_at(index)
		stack_changed.emit()


func duplicate_modifier(modifier) -> void:
	var index: int = stack.find(modifier)
	if index != -1:
		var duplicate = modifier.get_copy()
		add(duplicate)
		move(stack.size() - 1, index + 1)


func get_copy():
	var copy = get_script().new()
	for modifier in stack:
		copy.stack.push_back(modifier.duplicate())
	return copy


func get_index(modifier) -> int:
	return stack.find(modifier)


func is_using_edge_data() -> bool:
	for modifier in stack:
		if modifier.use_edge_data:
			return true

	return false


# Returns true if at least one modifier does not require shapes in order to work.
# (This is the case for the "Add single item" modifier for example)
func does_not_require_shapes() -> bool:
	for modifier in stack:
		if modifier.warning_ignore_no_shape:
			return true

	return false
