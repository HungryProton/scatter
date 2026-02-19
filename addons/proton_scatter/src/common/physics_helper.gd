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

var _rays_from_to_pairs: Array[Vector3]:
	set(value):
		_rays_from_to_pairs = value
		_ray_count = value.size() / 2 if value else 0
		_ray_cursor = 0
		
var _ray_count: int
var _ray_cursor: int

var _results: Array[Dictionary] = []
var _space_state: PhysicsDirectSpaceState3D


func _ready() -> void:
	set_physics_process(false)
	_main_thread_id = OS.get_thread_caller_id()
	_is_ready = true


func _exit_tree():
	if _job_in_progress:
		_job_in_progress = false
		job_completed.emit()


func execute(rays_from_to_pairs: Array[Vector3], collision_mask: int) -> Array[Dictionary]:
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

	_rays_from_to_pairs = rays_from_to_pairs
	_results.resize(_ray_count)
	
	_query.collision_mask = collision_mask
	
	_max_queries_per_frame = ProjectSettings.get_setting(MAX_PHYSICS_QUERIES_SETTING, 500)
	_job_in_progress = true
	set_physics_process.bind(true).call_deferred()

	await _until(job_completed, func(): return _job_in_progress, true)

	return _results.duplicate()

var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()

func _physics_process(_delta: float) -> void:
	if _rays_from_to_pairs.is_empty() or _ray_cursor > _ray_count:
		return

	if not _space_state:
		_space_state = get_tree().get_root().get_world_3d().get_direct_space_state()

	var pair_index: int = _ray_cursor * 2
	var batch_remaining: int = _max_queries_per_frame

	while _ray_cursor < _ray_count:
		_query.from = _rays_from_to_pairs[pair_index]
		
		if Vector3.INF == _query.from:
			pair_index += 2
			_ray_cursor += 1
			continue
		
		_query.to = _rays_from_to_pairs[pair_index + 1]

		_results[_ray_cursor] = _space_state.intersect_ray(_query) # TODO: Add support for other operations

		pair_index += 2
		_ray_cursor += 1
		
		batch_remaining -= 1
		if batch_remaining <= 0:
			return

	set_physics_process(false)
	_job_in_progress = false
	job_completed.emit()


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
