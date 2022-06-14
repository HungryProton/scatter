@tool
extends Resource


signal value_changed

const TransformList = preload("../common/transform_list.gd")


@export var stack: Array[Resource] = []

var owner: Node
var just_created := false
var undo_redo: UndoRedo


func update() -> TransformList:
	var transforms = TransformList.new()
	for modifier in stack:
		if modifier.enabled:
			modifier.process_transforms(transforms, owner.domain, owner.global_seed)

	return transforms


func add(modifier) -> void:
	stack.push_back(modifier)
	changed.emit()


func move(old_index: int, new_index: int) -> void:
	var modifier = stack.pop_at(old_index)
	stack.insert(new_index, modifier)


func remove(modifier) -> void:
	if stack.has(modifier):
		stack.erase(modifier)
		changed.emit()
