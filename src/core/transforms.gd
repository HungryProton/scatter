tool
extends Node


var list := []
var path # ScatterPath object


func add(count: int) -> void:
	for i in count:
		var t := Transform()
		list.push_back(t)


func remove(count: int) -> void:
	count = int(max(count, 0)) # Prevent using a negative number
	var new_size = max(list.size() - count, 0)
	list.resize(new_size)


func resize(count: int) -> void:
	var size = list.size()
	if count > size:
		add(count - size)
	else:
		remove(size - count)


func set_path(p: Path) -> void:
	path = p
