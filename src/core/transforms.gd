tool
extends Node


var list := []
var size: Vector3
var path


func set_count(count: int) -> void:
	for i in count:
		var t := Transform()
		list.push_back(t)


func set_path(p: Path) -> void:
	path = p
