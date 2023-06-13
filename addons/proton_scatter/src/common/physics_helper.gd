@tool
extends Node

# Runs jobs during the physics step.
# Only supports raycast for now, but can easilly be adapted to handle
# the other types of queries.

signal job_completed

const MAX_QUERIES_PER_FRAME = 400 # TODO: Expose in user settings


var _is_ready := false
var _space_state: PhysicsDirectSpaceState3D
var _queries: Array
var _results: Array[Dictionary]


func _ready() -> void:
	set_physics_process(false)
	_space_state = get_tree().get_root().get_world_3d().get_direct_space_state()
	_is_ready = true


func execute(queries: Array) -> Array[Dictionary]:
	if not _is_ready:
		await ready

	# Clear previous job
	_queries.clear()
	_results.clear()
	await get_tree().physics_frame

	_queries = queries
	set_physics_process.bind(true).call_deferred()

	await job_completed

	return _results.duplicate()


func _physics_process(_delta: float) -> void:
	if _queries.is_empty():
		return

	var steps = min(MAX_QUERIES_PER_FRAME, _queries.size())
	for i in steps:
		var q = _queries.pop_back()
		var hit := _space_state.intersect_ray(q) # TODO: Support other operations
		_results.push_back(hit)

	if _queries.is_empty():
		set_physics_process(false)
		_results.reverse()
		job_completed.emit()
