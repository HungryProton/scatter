tool
extends Node


signal stack_changed


export var stack := []
var just_created := false


func update(transforms, random_seed) -> void:
	for modifier in stack:
		if modifier.enabled:
			modifier.process_transforms(transforms, random_seed)


func duplicate_stack() -> Array:
	var res = []
	for m in stack:
		res.push_back(m.duplicate(7))
	return res


func add_modifier(modifier) -> void:
	stack.push_back(modifier)
	emit_signal("stack_changed")


func move_up(modifier) -> void:
	var index = stack.find(modifier)
	if index == 0 or index == -1:
		return
	stack.remove(index)
	stack.insert(index - 1, modifier)
	emit_signal("stack_changed")


func move_down(modifier) -> void:
	var index = stack.find(modifier)
	var last_index = stack.size() - 1
	if index == last_index or index == -1:
		return
	stack.remove(index)
	stack.insert(index + 1, modifier)
	emit_signal("stack_changed")


func remove(modifier) -> void:
	if stack.has(modifier):
		stack.erase(modifier)
		emit_signal("stack_changed")
