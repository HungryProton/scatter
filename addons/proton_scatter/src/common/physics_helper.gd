@tool
extends Node

# Runs jobs during the physics step.
# Only supports raycast for now, but can easilly be adapted to handle
# the other types of queries.

signal job_completed

const ProtonScatterParallel: = preload("res://addons/proton_scatter/src/common/parallel.gd")

const MAX_PHYSICS_QUERIES_SETTING := "addons/proton_scatter/max_physics_queries_per_frame"

const SKIP_RAY: Vector3 = Vector3.INF

var _is_ready: bool = false
var _job_in_progress: bool = false
var _max_queries_per_frame: int = 400
var _main_thread_id: int
var _space_state: PhysicsDirectSpaceState3D
var _parallel: ProtonScatterParallel = ProtonScatterParallel.new()

# Input
var _collision_mask: int
var _rays_from_to_pairs: Array[Vector3]

# Output
var _results: Array[Dictionary] = []



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

	var ray_count: int = rays_from_to_pairs.size() / 2

	_collision_mask = collision_mask
	_rays_from_to_pairs = rays_from_to_pairs
	_results.resize(ray_count)

	var max_queries_per_frame: int = ProjectSettings.get_setting(MAX_PHYSICS_QUERIES_SETTING, 500)

	_parallel.prepare("raycasts", ray_count, max_queries_per_frame, _raycasts_worker_task)

	_job_in_progress = true
	set_physics_process.bind(true).call_deferred()

	await _until(job_completed, func(): return _job_in_progress, true)

	return _results.duplicate()


func _physics_process(_delta: float) -> void:
	if not _space_state:
		_space_state = get_tree().get_root().get_world_3d().get_direct_space_state()

	# Do the max_queries x parallel; this keeps the setting backward compatible
	# while improving performance by as much as the used CPU allows.
	# Note that the server is not threadsafe, however we are in the space-state's
	# owning thread, and we block here while only doing read-only ops, so its fine.
	var items: int = _max_queries_per_frame * _parallel.get_max_parallel()
	if await _parallel.execute_work(items):
		return

	set_physics_process(false)
	_job_in_progress = false
	job_completed.emit()


func _raycasts_worker_task(from_ray: int, to_ray: int, task: Dictionary) -> void:

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.collision_mask = _collision_mask
	
	var pair_index: int = from_ray * 2
	for i: int in range(from_ray, to_ray):
		query.from = _rays_from_to_pairs[pair_index]
		
		if SKIP_RAY == query.from:
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
