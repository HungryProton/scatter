@tool
extends RefCounted


var list: Array[Transform3D] = []
var max_count := -1


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
func shuffle(random_seed := 0) -> void:
	var n = list.size()
	if n < 2:
		return

	var rng = RandomNumberGenerator.new()
	rng.set_seed(random_seed)

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
