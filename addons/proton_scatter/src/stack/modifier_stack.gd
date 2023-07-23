@tool
extends Resource


signal stack_changed
signal value_changed
signal transforms_ready


const ProtonScatter := preload("../scatter.gd")
const TransformList := preload("../common/transform_list.gd")
const BaseModifier := preload("../modifiers/base_modifier.gd")


@export var stack: Array[BaseModifier] = []

var just_created := false


func start_update(scatter_node: ProtonScatter, domain):
	var transforms = TransformList.new()

	for modifier in stack:
		await modifier.process_transforms(transforms, domain, scatter_node.global_seed)

	transforms_ready.emit(transforms)
	return transforms


func add(modifier: BaseModifier) -> void:
	stack.push_back(modifier)
	modifier.modifier_changed.connect(_on_modifier_changed)
	stack_changed.emit()


func move(old_index: int, new_index: int) -> void:
	var modifier = stack.pop_at(old_index)
	stack.insert(new_index, modifier)
	stack_changed.emit()


func remove(modifier: BaseModifier) -> void:
	if stack.has(modifier):
		stack.erase(modifier)
		stack_changed.emit()


func remove_at(index: int) -> void:
	if stack.size() > index:
		stack.remove_at(index)
		stack_changed.emit()


func duplicate_modifier(modifier: BaseModifier) -> void:
	var index: int = stack.find(modifier)
	if index != -1:
		var copy = modifier.get_copy()
		add(copy)
		move(stack.size() - 1, index + 1)


func get_copy():
	var copy = get_script().new()
	for modifier in stack:
		copy.add(modifier.duplicate())
	return copy


func get_index(modifier: BaseModifier) -> int:
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


func _on_modifier_changed() -> void:
	stack_changed.emit()
