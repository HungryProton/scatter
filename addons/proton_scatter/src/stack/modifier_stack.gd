@tool
class_name ProtonScatterModifierStack
extends Resource


signal stack_changed
signal value_changed
signal transforms_ready


const TransformList := preload("../common/transform_list.gd")


@export var stack: Array[ScatterBaseModifier] = []

var just_created := false
var parent: ProtonScatter

var _transforms_parts: Array[TransformList]

var _task_scatter_node: ProtonScatter
var _task_domain
var _task_modifiers: Array

func start_update(scatter_node: ProtonScatter, domain):
	var transforms: TransformList = TransformList.new()

	_task_scatter_node = scatter_node
	_task_domain = domain

	# Below 5000 there is little chance that the workerthreads overhead is worth it
	# Additionally; where specific seeds are used, the resulting
	# sequence can be different compared to older non-threading versions.
	# This would 'break' (or rather: change) existing scenes with little
	# volume, where a dev might rely on the specific result item placements.
	# Above a 1000 items, that becomes more unlikely.
	# Notice this can cause the start of the sequence to 'jump' (be different)
	# when switching between 4999 and 5000 items.
	const USE_WORKERTHREADS_THRESHOLD: int = 5000

	for modifier in stack:
		if transforms.size() < USE_WORKERTHREADS_THRESHOLD or not modifier.allow_parallel():
			await modifier.process_transforms(transforms, domain, scatter_node.global_seed)
		else:
			var core_count: int = max(1, OS.get_processor_count() - 2)
			_transforms_parts = _split_transforms_list(transforms, core_count)
			
			_task_modifiers.clear()
			for i: int in range(_transforms_parts.size()):
				_task_modifiers.append(modifier.duplicate())
			
			WorkerThreadPool.wait_for_group_task_completion(
				WorkerThreadPool.add_group_task(_parallel_part, _transforms_parts.size(), core_count)
			)
			
			transforms.clear()
			for result_part in _transforms_parts:
				transforms.append(result_part.list)
			
	_task_scatter_node = null
	_task_domain = null

	transforms_ready.emit(transforms)
	return transforms

func _parallel_part(part_index: int) -> void:
	await _task_modifiers[part_index].process_transforms(_transforms_parts[part_index], _task_domain, _task_scatter_node.global_seed)


func stop_update() -> void:
	for modifier in stack:
		modifier.interrupt()


func add(modifier: ScatterBaseModifier) -> void:
	stack.push_back(modifier)
	modifier.modifier_changed.connect(_on_modifier_changed)
	stack_changed.emit()


func move(old_index: int, new_index: int) -> void:
	var modifier = stack.pop_at(old_index)
	stack.insert(new_index, modifier)
	stack_changed.emit()


func remove(modifier: ScatterBaseModifier) -> void:
	if stack.has(modifier):
		stack.erase(modifier)
		stack_changed.emit()


func remove_at(index: int) -> void:
	if stack.size() > index:
		stack.remove_at(index)
		stack_changed.emit()


func duplicate_modifier(modifier: ScatterBaseModifier) -> void:
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


func get_index(modifier: ScatterBaseModifier) -> int:
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


func _split_transforms_list(list: TransformList, part_count: int) -> Array[TransformList]:
	var result: Array[TransformList] = []
	var part_size: int = max(1000, list.size() / part_count)
	
	var cursor: int = 0
	var remaining: int = list.size()
	
	while remaining > 0:
		var to: int = cursor + min(remaining, part_size)
		var part_list: TransformList = TransformList.new()
	
		part_list.append(list.list.slice(cursor, to))
		result.append(part_list)
		remaining -= to - cursor
		cursor = to
	return result
