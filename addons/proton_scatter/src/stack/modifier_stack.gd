@tool
class_name ProtonScatterModifierStack
extends Resource

const ProtonScatterParallel: = preload("res://addons/proton_scatter/src/common/parallel.gd")
const TransformList := preload("../common/transform_list.gd")
const JumpableRNG = preload("../common/random.gd")

signal stack_changed
signal value_changed
signal transforms_ready

@export var stack: Array[ScatterBaseModifier] = []

# Below 5000 there is little chance that the workerthreads overhead is worth it
# Note that above 5000 result of scatter is different from older pre-parallel
# versions.
const USE_WORKERTHREADS_THRESHOLD: int = 5000

var just_created := false
var parent: ProtonScatter


func start_update(scatter_node: ProtonScatter, domain):
	assert(parent)
	
	# TODO: Question: This doesnt fire in demo or unit tests; so either the argument or member can go?
	# (I suppose the member, as its only used locally here)
	assert(parent == scatter_node)

	var transforms: TransformList = TransformList.new()
	var rng: JumpableRNG = JumpableRNG.new()
	var parallel: ProtonScatterParallel = ProtonScatterParallel.new()

	for modifier in stack:
		var name: String = "%s_%s" % [ parent.name, modifier.display_name]
		
		rng.seed = modifier.get_rng_seed(scatter_node.global_seed)
		
		var run_parallel: bool = modifier.allow_parallel() and transforms.size() > USE_WORKERTHREADS_THRESHOLD
		if not run_parallel:
			await modifier.process_transforms(transforms, domain, rng)
			continue

		parallel.set_rng_seed(rng.seed)

		var splits: Array[TransformList] = _split_transforms_list(transforms, parallel.get_num_parallel())
	
		parallel.prepare(name, transforms.size(), splits[0].size(), _process_transforms_split, 
			func(index: int, task: Dictionary):
				task["split"] = splits[index]
				task["modifier"] = modifier.duplicate() # duplicate Still needed? not sure TODO: test without
				task["domain"] = domain
		)
		
		await parallel.execute_all()

		transforms.clear()
		for result_part in splits:
			transforms.append(result_part.list)

			
	transforms_ready.emit(transforms)
	return transforms


func _process_transforms_split(task: Dictionary) -> void:
	var modifier: ScatterBaseModifier = task["modifier"]
	var split: TransformList = task['split']
	await modifier.process_transforms(split, task['domain'], task['rng'])


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
	var part_size: int = max(1000, max(1, list.size() / part_count))
	
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
