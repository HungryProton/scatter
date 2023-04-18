@tool
extends Node

# Runs jobs during the physics step.
# Only supports raycast for now, but can easilly be adapted to handle
# the other types of queries.


signal job_canceled
signal job_completed

const MAX_QUERIES_PER_FRAME = 400 # TODO: Expose in user settings


var _queries: Array
var _results: Array[Dictionary]
var _job_in_progress := false
var _cancel_current := false


func execute(queries: Array) -> Array[Dictionary]:
	if _job_in_progress:
		_cancel_current = true
		await job_canceled

	_results.clear()
	_queries = queries
	_queries.reverse()
	_job_in_progress = true

	await job_completed

	_job_in_progress = false
	return _results.duplicate()


func _physics_process(_delta: float) -> void:
	if _cancel_current:
		_cancel_current = false
		_job_in_progress = false
		_results.clear()
		job_canceled.emit()
		return

	if not _job_in_progress:
		return

	var space_state: PhysicsDirectSpaceState3D = get_tree().get_root().get_world_3d().get_direct_space_state()
	var steps = min(MAX_QUERIES_PER_FRAME, _queries.size())

	for i in steps:
		var q = _queries.pop_back()
		var hit := space_state.intersect_ray(q) # TODO: Support other operations
		_results.push_back(hit)

	if _queries.is_empty():
		_job_in_progress = false
		job_completed.emit()
