@tool
extends RefCounted

const ProtonScatterParallel: = preload("res://addons/proton_scatter/src/common/parallel.gd")

var list: Array[Transform3D]:
	set(value):
		list = value
		_aabb = _INVALID_AABB
		
		
var max_count := -1



var aabb: AABB = AABB():
	get():
		if _INVALID_AABB !=_aabb:
			return _aabb
		
		_aabb = aabb_from_array(list)
		return _aabb
		

const _INVALID_AABB: AABB = AABB()
var _aabb: AABB = _INVALID_AABB


func add(count: int) -> void:
	for i in count:
		var t := Transform3D()
		list.push_back(t)


func append(array: Array[Transform3D]) -> void:
	list.append_array(array)


func remove(count: int) -> void:
	count = int(max(count, 0)) # Prevent using a negative number
	var new_size = max(list.size() - count, 0)
	list.resize(new_size)


func resize(count: int) -> void:
	if max_count >= 0:
		count = int(min(count, max_count))

	var current_count = list.size()
	if count > current_count:
		add(count - current_count)
	else:
		remove(current_count - count)


# TODO: Faster algorithm probably exists for this, research an alternatives
# if this ever becomes a performance bottleneck.
func shuffle(rng) -> void:
	var n = list.size()
	if n < 2:
		return

	var i = n - 1
	var j
	var tmp
	while i >= 1:
		j = rng.randi() % (i + 1)
		tmp = list[j]
		list[j] = list[i]
		list[i] = tmp
		i -= 1


func clear() -> void:
	list = []


func is_empty() -> bool:
	return list.is_empty()


func size() -> int:
	return list.size()


func enforce_uniform_scale() -> void:
	for i: int in list.size():
		var t: Transform3D = list[i]
		var current_scale: Vector3 = t.basis.get_scale()
		var scale := Vector3.ONE * (current_scale.x + current_scale.y + current_scale.z) / 3.0
		list[i] = list[i].orthonormalized().scaled_local(scale)

## Call when having modifies list members; this ensures AABB is reevaluated if accessed
func invalidate() -> void:
	_aabb = _INVALID_AABB

# Multidimensional array as used by instancing grid cannot be typed AFAIK
static func aabb_from_array(transforms: Array) -> AABB:
	if transforms.is_empty():
		return AABB()

	var result: AABB = AABB(transforms[0].origin, Vector3.ZERO)

	for t: Transform3D in transforms:
		result = result.expand(t.origin)

	return result
	
# Parallel AABB works, but aint worth it (timed it, the operation is too light)	
#static func _aabb_from_array_parallel(transforms: Array) -> AABB:
	#var result: AABB = AABB(transforms[0].origin, Vector3.ZERO)
	#var parallel: ProtonScatterParallel = ProtonScatterParallel.new()
	#
	#parallel.prepare("transforms_aabb", transforms.size(), ProtonScatterParallel.TASK_ITEM_LIMIT_AUTO,_aabb_worker,
		#func(index: int, task: Dictionary):
			#task["transforms"] = transforms
			#task["aabb"] = result
	#)
#
	#parallel.execute_work()
	#
	#for results: Dictionary in parallel.completed_tasks:
		#result = result.merge(results['aabb'])
#
	#assert(result != AABB(transforms[0].origin, Vector3.ZERO))
	#
	#return result
#
#
#static func _aabb_worker(from: int, to: int, task: Dictionary) -> void:
	#var result: AABB = task["aabb"]
	#var transforms: Array = task['transforms']
	#
	#for i: int in range(from, to):
		#result = result.expand(transforms[i].origin)
	#
	#task["aabb"] = result
