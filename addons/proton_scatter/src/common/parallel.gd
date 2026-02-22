@tool
extends RefCounted

const JumpableRNG = preload("../common/random.gd")


const MINIMUM_ITEMS_PER_TASK: int = 500

# Master kill switch for quick check if any issue is due to paralellisation or not
const ENABLE_PARALLELISATION: bool = true  

const NO_EXECUTOR_PREPARED: Callable = Callable()

# Optionally can be used to toggle on per case if needed (might link to UI)
var enabled: bool = true

var _name: String # Convinient for debugging
var _tasks: Array[Dictionary] = []
var _executor: Callable = NO_EXECUTOR_PREPARED
var _rng_seed = 0
var _rng_steps_per_iteration = 1

var _run_threaded: bool:
	get(): 
		return enabled and ENABLE_PARALLELISATION and _tasks.size() > 1

var _core_count: int:
	get():
		if !_run_threaded:
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


## Prepare parallel processing
## If max_items_per_task < 0, distribution size is automatic
## Executor is func executor(task: Dictionary)
## Task initializer is func task_initializer(index: int, task: Dictionary)
## Task dict has 'from' and 'to' indexes, relating to the total item count
## Task initializer can be used to enrich the task data
func prepare(name: String, total_item_count: int, max_items_per_task: int, executor: Callable, task_initializer: Callable= Callable()) -> void:
	assert(not executor.is_null() and executor.get_argument_count() == 1)
	assert(task_initializer.is_null() or task_initializer.get_argument_count() == 2)

	_name = name

	var distribute_remaining: int = total_item_count
	_core_count = max(1, OS.get_processor_count() - 2)

	if max_items_per_task <= 0:
		max_items_per_task = total_item_count / _core_count

	max_items_per_task = max(max_items_per_task, MINIMUM_ITEMS_PER_TASK)
	
	var from: int = 0
	_tasks.clear()
	while distribute_remaining > 0:
		var task_length: int = min(distribute_remaining, max_items_per_task)
		var to: int = from + task_length
		
		# Keep rng sequence consistent regardless of split distribution and order
		var rng: JumpableRNG = JumpableRNG.new()
		rng.seed = _rng_seed
		rng.jump(from * _rng_steps_per_iteration)
		
		var task: Dictionary = {
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
	
	_executor = executor


func is_done() -> bool:
	return _tasks.is_empty()


func get_num_parallel() -> int:
	return _core_count


## Run all work in 1 go
func execute_all() -> void:
	if is_done():
		return
	
	var task_count: int = _tasks.size()
		
	if _run_threaded:
		WorkerThreadPool.wait_for_group_task_completion(
			WorkerThreadPool.add_group_task(_worker_task, task_count, _core_count)
		)
		_remove_done_tasks(task_count)
		return
	
	await _execute_blocking(task_count)


## Run 1 batch of work
## Returns true if there is more work, false when done
func execute_batch() -> bool:
	if is_done():
		return false

	var batch_size: int = min(_tasks.size(), _core_count)

	if _run_threaded:
		WorkerThreadPool.wait_for_group_task_completion(
			WorkerThreadPool.add_group_task(_worker_task, batch_size, _core_count)
		)

		_remove_done_tasks(batch_size)

		return not is_done()

	await _execute_blocking(1)
	return not is_done()


func _worker_task(task_index: int) -> void:
	var task: Dictionary = _tasks[task_index]
	#print("task %s start, range %s to %s" % [ _name, task['from'], task['to']])
	await _executor.call(task)
	#print("task %s finished" % [ _name ])

# Used when parallel disabled, or just 1 task (only gives thread sync overhead)
func _execute_blocking(task_count: int) -> void:
	if is_done():
		return

	var execute_count: int = min(task_count, _tasks.size())
	for i: int in execute_count:
		await _worker_task(i)

	_remove_done_tasks(execute_count)


func _remove_done_tasks(executed_count: int) -> void:
	if executed_count <= 0:
		return
		
	assert(executed_count <= _tasks.size())
	
	if executed_count == _tasks.size():
		_tasks.clear()
	else:
		_tasks = _tasks.slice(executed_count, _tasks.size())
	
	if is_done():
		_executor = NO_EXECUTOR_PREPARED


## Sets the RNG seed, and how many randoms consumed per iteration (int = 1, float = 2)
## Must be called before prepare
##
## Note that currently just using the default of 1000, to ensure no overlaps occur;
## Considered adding it as a property to the modifiers but unfortunatly they
## dont consume in a deterministic way; so thats really too bad; otherwise
## exact-match scene compatibility with older versions would have been kept
## for >=5000 amount scatters as well. "got so close, but no sigar...."
func set_rng_seed(seed: int, steps_per_iteration: int = 1000) -> void:
	assert(_executor == NO_EXECUTOR_PREPARED)
	_rng_seed = seed
	_rng_steps_per_iteration = steps_per_iteration
