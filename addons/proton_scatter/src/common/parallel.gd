@tool
extends RefCounted

const JumpableRNG = preload("../common/random.gd")

const WORK_AMOUNT_ALL: int = 0
const TASK_ITEM_LIMIT_AUTO: int = 0

const _MINIMUM_ITEMS_PER_TASK: int = 1000
# Limit tasks; this prevents dragging out completion time by one or more
# workers that happen to become available late (they start later).
const _MAXIMUM_ITEMS_PER_TASK: int = 5000

# Master kill switch for quick check if any issue is due to paralellisation or not
const _ENABLE_PARALLELISATION: bool = true  

const _NO_EXECUTOR_PREPARED: Callable = Callable()

# Limit overhead to 1 task unless there is substantial work to gain from parallel
const _PARALLEL_MINIMUM_ITEMS_THRESHOLD = _MINIMUM_ITEMS_PER_TASK * 5


# Optionally can be used to toggle on per case if needed (might link to UI)
var enabled: bool = true

var _name: String # Convinient for debugging
var _tasks: Array[Dictionary] = []
var _executor: Callable = _NO_EXECUTOR_PREPARED
var _rng_seed = 0
var _rng_steps_per_iteration = 1

var _enabled: bool:
	get(): 
		return enabled and _ENABLE_PARALLELISATION 

var _max_parallel: int:
	get():
		if not _enabled:
			return 1
		
		var reserved_cores: int = 1 # Main thread
		
		var rendering_thread_mode = ProjectSettings.get_setting("rendering/driver/threads/thread_model")
		match rendering_thread_mode:
			0: reserved_cores += 2 # pooled
			1: reserved_cores += 0 # on main thread
			2: reserved_cores += 1 # dedicated
			_: 
				push_warning("ProtonScatter parallelisation balancing unknown rendering threading model")
				reserved_cores += 2 # Guess
		
		var physics_threaded = ProjectSettings.get_setting("physics/3d/run_on_separate_thread")
		if physics_threaded:
			reserved_cores += 1
			
		return max(1, OS.get_processor_count() - reserved_cores)


## Get the task size that will be used given the count and per task limit
## Use this if need to pre-fab splits before preparing
func get_task_size(total_item_count: int, task_item_limit: int = TASK_ITEM_LIMIT_AUTO) -> int:
	
	# To keep older scenes placement exact match compatible dont split small amounts
	# as the RNG jumps using fixed consumption offset will change the sequence.
	# Only relevant for smaller sets, as its very unlikely someone relies on 
	# exact placement on bulk items. Doing this here instead on calling side
	# ensures the stack and all modifiers adhere to it.
	if !_enabled or total_item_count <= _PARALLEL_MINIMUM_ITEMS_THRESHOLD:
		# This will cause 1 task, and having just 1 task will run in same thread
		return total_item_count
	
	var items_per_task: int = total_item_count / _max_parallel

	items_per_task = min(items_per_task, _MAXIMUM_ITEMS_PER_TASK)
	items_per_task = max(items_per_task, _MINIMUM_ITEMS_PER_TASK)

	# Provided overrides internal constraints
	if task_item_limit > TASK_ITEM_LIMIT_AUTO:
		items_per_task = min(items_per_task, task_item_limit)

	return items_per_task


## Prepare parallel processing
## If max_items_per_task < 0, distribution size is automatic
## Executor is func executor(from: int, to: int, task: Dictionary)
## Task initializer is func task_initializer(index: int, task: Dictionary)
## Task dict has a 'rng': RandomNumberGenerator, which is jumped to the from position
## Task initializer can be used to enrich the task data further
func prepare(name: String, total_item_count: int, task_item_limit: int, executor: Callable, task_initializer: Callable= Callable()) -> void:
	assert(not executor.is_null() and executor.get_argument_count() == 3)
	assert(task_initializer.is_null() or task_initializer.get_argument_count() == 2)

	_name = name

	var distribute_remaining: int = total_item_count

	var items_per_task: int = get_task_size(total_item_count, task_item_limit)

	var from: int = 0
	_tasks.clear()
	while distribute_remaining > 0:
		var task_length: int = min(distribute_remaining, items_per_task)
		var to: int = from + task_length
		
		# Keep rng sequence consistent regardless of split distribution and order
		var rng: JumpableRNG = JumpableRNG.new()
		rng.seed = _rng_seed
		rng.jump(from * _rng_steps_per_iteration)
		
		var task: Dictionary = {
			"index": _tasks.size(),
			"rng": rng,
			"from": from,
			"to": to
		}
		
		if not task_initializer.is_null():
			assert(task_initializer.get_argument_count() == 2)
			task_initializer.call(_tasks.size(), task)
		
		_tasks.append(task)
		
		from += task_length
		distribute_remaining -= task_length

	if _tasks.is_empty():
		return
		
	#print(name + str(_tasks))
	
	_executor = executor

## Returns true if work is completed; false if tasks (and thus items) left
func is_done() -> bool:
	return _tasks.is_empty()


## Get the max parallel threads used to complete tasks
func get_max_parallel() -> int:
	return _max_parallel if _enabled else 1


## Execute the given amount of work (which is rounded up to the task needed)
## returns true if there is more work, false if done
func execute_work(item_amount: int = WORK_AMOUNT_ALL) -> bool:
	if is_done():
		return false
	
	if _enabled and _tasks.size() > 1:
		var task_count: int = _get_task_count_for_work(item_amount)
		WorkerThreadPool.wait_for_group_task_completion(
			WorkerThreadPool.add_group_task(_worker_task, task_count, _max_parallel)
		)
		_remove_done_tasks(task_count)
		return true
	
	return await _execute_in_current_thread(item_amount)

## Invoke executor to complete the task
func _worker_task(task_index: int) -> void:
	var task: Dictionary = _tasks[task_index]
	#print("task %s start, range %s to %s" % [ _name, task['from'], task['to']])
	await _executor.call(task['from'], task['to'], task)
	#print("task %s end, range %s to %s" % [ _name, task['from'], task['to']])


## Execute in current thread
## Used when parallel disabled, or just 1 task (only gives thread sync overhead)
## Returns true if there is more work left
func _execute_in_current_thread(item_amount: int = WORK_AMOUNT_ALL) -> bool:
	if is_done():
		return false

	var task_count: int = _get_task_count_for_work(item_amount)

	for t: int in task_count:
		await _worker_task(t)
		
	_remove_done_tasks(task_count)

	return not is_done()

## Get the amount of tasks to complete to work the given item count.
## Note this will not split tasks, so will round up to nearest.
func _get_task_count_for_work(item_count: int = WORK_AMOUNT_ALL) -> int:
	if item_count <= WORK_AMOUNT_ALL:
		return _tasks.size()
		
	var task_count: int = 0
	while item_count > 0 and task_count < _tasks.size():
		var task: Dictionary = _tasks[task_count]
		item_count -= task['to'] - task['from']
		task_count += 1
		
	return task_count


func _remove_done_tasks(executed_count: int) -> void:
	if executed_count <= 0:
		return
		
	assert(executed_count <= _tasks.size())
	
	if executed_count == _tasks.size():
		_tasks.clear()
	else:
		_tasks = _tasks.slice(executed_count, _tasks.size())
	
	if is_done():
		_executor = _NO_EXECUTOR_PREPARED


## Sets the RNG seed, and how many randoms consumed per iteration (int = 1, float = 2)
## Must be called before prepare
##
## Note that currently just using the default of 1000, to ensure no overlaps occur;
## Considered adding it as a property to the modifiers but unfortunatly they
## dont consume in a deterministic way; so thats really too bad; otherwise
## exact-match scene compatibility with older versions would have been kept
## for >=_PARALLEL_MINIMUM_ITEMS_THRESHOLD amount scatters as well. "got so close, but no sigar...."
func set_rng_seed(seed: int, steps_per_iteration: int = 1000) -> void:
	assert(_executor == _NO_EXECUTOR_PREPARED)
	_rng_seed = seed
	_rng_steps_per_iteration = steps_per_iteration
