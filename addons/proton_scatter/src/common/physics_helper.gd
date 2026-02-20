@tool
extends Node

# Runs jobs during the physics step.
# Only supports raycast for now, but can easilly be adapted to handle
# the other types of queries.

signal job_completed


const MAX_PHYSICS_QUERIES_SETTING := "addons/proton_scatter/max_physics_queries_per_frame"


var _is_ready: bool = false
var _job_in_progress: bool = false
var _max_queries_per_frame: int = 400
var _main_thread_id: int
var _space_state: PhysicsDirectSpaceState3D

# Input
var _collision_mask: int
var _rays_from_to_pairs: Array[Vector3]:
	set(value):
		_rays_from_to_pairs = value
		_ray_count = value.size() / 2 if value else 0
		_ray_cursor = 0

var _ray_count: int = 0
var _ray_cursor: int = 0

# Outputs
var _results: Array[Dictionary] = []

# Worker data distribution
var _physics_task_segments: Array[Dictionary] = []

var is_done: bool:
	get():
		return _ray_cursor >= _ray_count

func _ready() -> void:
	set_physics_process(false)
	_main_thread_id = OS.get_thread_caller_id()
	_is_ready = true


func _exit_tree():
	if _job_in_progress:
		_job_in_progress = false
		job_completed.emit()


func execute_raycasts(rays_from_to_pairs: Array[Vector3], collision_mask: int) -> Array[Dictionary]:
	if not _is_ready:
		printerr("ProtonScatter error: Calling execute on a PhysicsHelper before it's ready, this should not happen.")
		return []

	# Don't execute physics queries, if the node is not inside the tree.
	# This avoids infinite loops, because the _physics_process will never be executed.
	# This happens when the Scatter node is removed, while it perform a rebuild with a Thread.
	if not is_inside_tree():
		printerr("ProtonScatter error: Calling execute on a PhysicsHelper while the node is not inside the tree.")
		return []

	# Clear previous job if any
	_rays_from_to_pairs.clear()

	if _job_in_progress:
		await _until(get_tree().physics_frame, func(): return _job_in_progress)

	_collision_mask = collision_mask
	_rays_from_to_pairs = rays_from_to_pairs
	_results.resize(_ray_count)

	
	_max_queries_per_frame = ProjectSettings.get_setting(MAX_PHYSICS_QUERIES_SETTING, 500)
	_job_in_progress = true
	set_physics_process.bind(true).call_deferred()

	await _until(job_completed, func(): return _job_in_progress, true)

	return _results.duplicate()


func _physics_process(_delta: float) -> void:
	if is_done:
		return

	if not _space_state:
		_space_state = get_tree().get_root().get_world_3d().get_direct_space_state()

	_parallel_raycasts()
	
	if not is_done:
		return

	set_physics_process(false)
	_job_in_progress = false
	job_completed.emit()


# Do the max_queries, on N cores in parallel; this keeps the setting backward compatible
# while improving performance by as much as the used CPU allows.
func _parallel_raycasts() -> void:
	var work_remaining: int = _ray_count - _ray_cursor
	var core_count: int = max(1, OS.get_processor_count() - 2)
	var batch_size: int = min(work_remaining, core_count * _max_queries_per_frame)

	_physics_task_segments.clear()
	
	# Define indexable segements for worker tasks
	var batch_remaining: int = batch_size
	while batch_remaining > 0:
		var to: int = _ray_cursor + (min(batch_remaining, _max_queries_per_frame))
		_physics_task_segments.append( {
			"from": _ray_cursor,
			"to": to
		})
		batch_remaining -= to - _ray_cursor
		_ray_cursor = to
	
	# Execute in parallel as a group; since we are in physics_process, and are not
	# mutating anything in the space state, it is safe to query in parallel.
	WorkerThreadPool.wait_for_group_task_completion(
		WorkerThreadPool.add_group_task(_raycasts_worker_task, _physics_task_segments.size(), core_count)
	)


func _raycasts_worker_task(segment_index: int) -> void:
	var task_segment: Dictionary = _physics_task_segments[segment_index] 
	var from_ray: int = task_segment["from"] 
	var to_ray: int = task_segment["to"] 

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.collision_mask = _collision_mask
	
	var pair_index: int = from_ray * 2
	for i: int in range(from_ray, to_ray):
		query.from = _rays_from_to_pairs[pair_index]
		
		if Vector3.INF == query.from:
			pair_index += 2
			continue
		
		query.to = _rays_from_to_pairs[pair_index + 1]
		_results[i] = _space_state.intersect_ray(query)
		pair_index += 2



func _in_main_thread() -> bool:
	return OS.get_thread_caller_id() == _main_thread_id


func _until(s: Signal, callable: Callable, physics := false) -> void:
	if _in_main_thread():
		await s
		return

	# Called from a sub thread
	var delay: int = 0
	if physics:
		delay = round(get_physics_process_delta_time() * 100.0)
	else:
		delay = round(get_process_delta_time() * 100.0)

	while callable.call():
		OS.delay_msec(delay)
		if not is_inside_tree():
			return
