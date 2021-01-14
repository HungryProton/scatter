tool
extends Node


signal stack_changed


export var stack := []
var just_created := false
var undo_redo: UndoRedo


func update(transforms, random_seed : int) -> void:
	for modifier in stack:
		if modifier.enabled:
			modifier.process_transforms(transforms, random_seed)


func duplicate_stack() -> Array:
	var res = []
	for m in stack:
		res.push_back(m.duplicate(7))
	return res


func add_modifier(modifier) -> void:
	var restore : Array = duplicate_stack()
	stack.push_back(modifier)
	_create_undo_action("Added Modifier", restore)
	emit_signal("stack_changed")


func move_up(modifier) -> void:
	var index : int = stack.find(modifier)
	if index == 0 or index == -1:
		return
	
	var restore : Array = duplicate_stack()
	stack.remove(index)
	stack.insert(index - 1, modifier)
	_create_undo_action("Moved Modifier Up", restore)
		
	emit_signal("stack_changed")


func move_down(modifier) -> void:
	var index : int = stack.find(modifier)
	var last_index : int = stack.size() - 1
	
	if index == last_index or index == -1:
		return
	
	var restore : Array = duplicate_stack()
	stack.remove(index)
	stack.insert(index + 1, modifier)
	_create_undo_action("Moved Modifier Down", restore)
	
	emit_signal("stack_changed")


func remove(modifier) -> void:
	if stack.has(modifier):
		var restore : Array = duplicate_stack()
		stack.erase(modifier)
		_create_undo_action("Removed Modifier", restore)
		emit_signal("stack_changed")


func _create_undo_action(name : String, restore) -> void:
	if undo_redo:
		undo_redo.create_action(name)
		undo_redo.add_undo_method(self, "_restore_stack", restore)
		undo_redo.add_do_method(self, "_restore_stack", duplicate_stack())
		undo_redo.commit_action()


func _restore_stack(s : Array) -> void:
	stack = s
	emit_signal("stack_changed")
