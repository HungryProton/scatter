@tool
extends Resource


signal stack_changed
signal value_changed


const TransformList = preload("../common/transform_list.gd")


@export var stack: Array[Resource] = []

var just_created := false
var undo_redo: UndoRedo
var documentation


func update(scatter_node: Node3D, domain) -> TransformList:
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
